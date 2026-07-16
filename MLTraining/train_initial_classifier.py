#!/usr/bin/env python3
"""Entraînement du modèle Core ML initial de Jardin Intelligent.

Transfert d'apprentissage (MobileNetV3-Small) sur un dataset organisé en dossiers
par classe, puis conversion en `PlantClassifier.mlpackage` à glisser dans la cible
Xcode de l'app (l'app le détecte automatiquement ; sans lui, elle fonctionne avec
la taxonomie Vision + le classifieur personnel).

Datasets publics conseillés :
  - PlantVillage (maladies + espèces)  : https://github.com/spMohanty/PlantVillage-Dataset
  - iNaturalist (espèces, licences CC) : https://www.inaturalist.org/pages/developers
  - Pl@ntNet-300K                      : https://zenodo.org/records/5645731

Arborescence attendue (labels en snake_case, ils deviennent les classes du modèle) :
    datasets/
      tomate/         *.jpg
      tomate_mildiou/ *.jpg
      basilic/        *.jpg
      ...

Usage :
    pip install -r requirements.txt
    python3 train_initial_classifier.py --data-dir datasets --epochs 8 --out output/

Alternative sans Python : l'app « Create ML » de Xcode (modèle « Image
Classification », augmentations activées) produit un .mlmodel équivalent.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import torch
import torch.nn as nn
from torch.utils.data import DataLoader, random_split
from torchvision import datasets, models, transforms

IMAGE_SIZE = 224
NORM_MEAN = [0.485, 0.456, 0.406]
NORM_STD = [0.229, 0.224, 0.225]


def build_loaders(data_dir: Path, batch_size: int) -> tuple[DataLoader, DataLoader, list[str]]:
    train_tf = transforms.Compose([
        transforms.RandomResizedCrop(IMAGE_SIZE, scale=(0.7, 1.0)),
        transforms.RandomHorizontalFlip(),
        transforms.ColorJitter(brightness=0.25, contrast=0.2, saturation=0.2),
        transforms.RandomRotation(15),
        transforms.ToTensor(),
        transforms.Normalize(NORM_MEAN, NORM_STD),
    ])
    eval_tf = transforms.Compose([
        transforms.Resize(256),
        transforms.CenterCrop(IMAGE_SIZE),
        transforms.ToTensor(),
        transforms.Normalize(NORM_MEAN, NORM_STD),
    ])

    full = datasets.ImageFolder(data_dir)
    classes = full.classes
    val_size = max(1, int(len(full) * 0.15))
    generator = torch.Generator().manual_seed(42)
    train_set, val_set = random_split(full, [len(full) - val_size, val_size], generator=generator)
    train_set.dataset.transform = train_tf

    # random_split partage le même dataset sous-jacent : on rouvre pour la validation.
    val_view = datasets.ImageFolder(data_dir, transform=eval_tf)
    val_set = torch.utils.data.Subset(val_view, val_set.indices)

    return (DataLoader(train_set, batch_size=batch_size, shuffle=True, num_workers=2),
            DataLoader(val_set, batch_size=batch_size, num_workers=2),
            classes)


def build_model(num_classes: int) -> nn.Module:
    model = models.mobilenet_v3_small(weights=models.MobileNet_V3_Small_Weights.DEFAULT)
    for param in model.features.parameters():
        param.requires_grad = False
    model.classifier[3] = nn.Linear(model.classifier[3].in_features, num_classes)
    return model


def train(model: nn.Module, train_loader: DataLoader, val_loader: DataLoader,
          epochs: int, lr: float, device: torch.device) -> None:
    criterion = nn.CrossEntropyLoss()
    optimizer = torch.optim.AdamW(
        [p for p in model.parameters() if p.requires_grad], lr=lr
    )
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=epochs)

    for epoch in range(epochs):
        model.train()
        running_loss, seen = 0.0, 0
        for images, labels in train_loader:
            images, labels = images.to(device), labels.to(device)
            optimizer.zero_grad()
            loss = criterion(model(images), labels)
            loss.backward()
            optimizer.step()
            running_loss += loss.item() * images.size(0)
            seen += images.size(0)
        scheduler.step()

        model.eval()
        correct, total = 0, 0
        with torch.no_grad():
            for images, labels in val_loader:
                images, labels = images.to(device), labels.to(device)
                predictions = model(images).argmax(dim=1)
                correct += (predictions == labels).sum().item()
                total += labels.size(0)
        print(f"époque {epoch + 1}/{epochs}  perte={running_loss / max(seen, 1):.4f}  "
              f"val_acc={correct / max(total, 1):.1%}")


def export_coreml(model: nn.Module, classes: list[str], out_dir: Path) -> Path:
    import coremltools as ct

    model.eval()
    example = torch.rand(1, 3, IMAGE_SIZE, IMAGE_SIZE)
    traced = torch.jit.trace(model, example)

    # Normalisation intégrée au modèle : l'app envoie l'image brute via Vision.
    scale = 1 / (0.226 * 255.0)
    bias = [-m / s for m, s in zip(NORM_MEAN, [0.226] * 3)]

    mlmodel = ct.convert(
        traced,
        inputs=[ct.ImageType(name="image", shape=example.shape, scale=scale, bias=bias)],
        classifier_config=ct.ClassifierConfig(classes),
        convert_to="mlprogram",
        minimum_deployment_target=ct.target.iOS17,
    )
    mlmodel.author = "Jardin Intelligent"
    mlmodel.short_description = ("Classifieur de plantes et maladies entraîné par "
                                 "transfert (MobileNetV3-Small).")
    mlmodel.license = "Voir licences des datasets d'entraînement"

    out_path = out_dir / "PlantClassifier.mlpackage"
    mlmodel.save(str(out_path))
    return out_path


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--data-dir", type=Path, required=True,
                        help="dossier dataset (un sous-dossier par classe)")
    parser.add_argument("--out", type=Path, default=Path("output"))
    parser.add_argument("--epochs", type=int, default=8)
    parser.add_argument("--batch-size", type=int, default=32)
    parser.add_argument("--lr", type=float, default=1e-3)
    args = parser.parse_args()

    device = torch.device("mps" if torch.backends.mps.is_available()
                          else "cuda" if torch.cuda.is_available() else "cpu")
    print(f"Appareil : {device}")

    train_loader, val_loader, classes = build_loaders(args.data_dir, args.batch_size)
    print(f"{len(classes)} classes : {', '.join(classes[:10])}{'…' if len(classes) > 10 else ''}")

    model = build_model(len(classes)).to(device)
    train(model, train_loader, val_loader, args.epochs, args.lr, device)

    args.out.mkdir(parents=True, exist_ok=True)
    (args.out / "classes.json").write_text(json.dumps(classes, ensure_ascii=False, indent=2),
                                           encoding="utf-8")
    torch.save(model.state_dict(), args.out / "plant_classifier.pt")
    package = export_coreml(model.cpu(), classes, args.out)

    print(f"\nModèle Core ML : {package}")
    print("→ Glissez PlantClassifier.mlpackage dans la cible JardinIntelligent (Xcode).")
    print("  L'app le charge automatiquement (BundledCoreMLIdentifier).")


if __name__ == "__main__":
    main()
