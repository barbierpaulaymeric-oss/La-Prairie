#!/usr/bin/env python3
"""Réentraînement à partir des données d'apprentissage exportées par l'app.

L'app exporte (Réglages → Données d'apprentissage) un dossier :
    JardinApprentissage-<date>/
      manifest.json     # étiquettes, tags, sources, empreintes Vision (base64)
      images/<id>.jpg   # photos validées/corrigées par l'utilisateur

Ce script :
  1. fusionne ces images dans un dataset « dossier par classe » (les corrections
     utilisateur comptent double : ce sont les exemples les plus informatifs) ;
  2. relance l'entraînement via train_initial_classifier.py ;
  3. (option --knn) construit en plus un modèle kNN Core ML *updatable* à partir
     des empreintes exportées — utile si vous préférez la mise à jour on-device
     via MLUpdateTask au kNN Swift intégré à l'app.

Usage :
    python3 retrain_from_export.py --export ~/JardinApprentissage-2026-07-16 \\
        --data-dir datasets --epochs 8
    python3 retrain_from_export.py --export <dossier> --knn --out output/
"""

from __future__ import annotations

import argparse
import base64
import json
import shutil
import struct
import subprocess
import sys
import unicodedata
from pathlib import Path


def slugify(label: str) -> str:
    normalized = unicodedata.normalize("NFKD", label).encode("ascii", "ignore").decode()
    cleaned = "".join(c if c.isalnum() else "_" for c in normalized.lower())
    return "_".join(filter(None, cleaned.split("_"))) or "inconnu"


def load_manifest(export_dir: Path) -> dict:
    manifest_path = export_dir / "manifest.json"
    if not manifest_path.exists():
        raise SystemExit(f"manifest.json introuvable dans {export_dir}")
    return json.loads(manifest_path.read_text(encoding="utf-8"))


def merge_into_dataset(export_dir: Path, data_dir: Path) -> int:
    manifest = load_manifest(export_dir)
    copied = 0
    for example in manifest["examples"]:
        image_file = example.get("imageFile")
        if not image_file:
            continue
        source_path = export_dir / image_file
        if not source_path.exists():
            continue
        class_dir = data_dir / slugify(example["label"])
        class_dir.mkdir(parents=True, exist_ok=True)

        # Les corrections utilisateur sont dupliquées : sur-échantillonnage simple
        # des exemples à plus forte valeur d'apprentissage.
        repeats = 2 if example.get("source") == "correction" else 1
        for i in range(repeats):
            suffix = f"_{i}" if i else ""
            shutil.copyfile(source_path, class_dir / f"user_{example['id']}{suffix}.jpg")
            copied += 1
    return copied


def build_updatable_knn(export_dir: Path, out_dir: Path) -> Path:
    """Modèle kNN Core ML updatable (entrée : vecteur d'empreinte Vision)."""
    import coremltools as ct
    from coremltools.models.nearest_neighbors import KNearestNeighborsClassifierBuilder

    manifest = load_manifest(export_dir)
    vectors: list[list[float]] = []
    labels: list[str] = []
    for example in manifest["examples"]:
        b64 = example.get("featurePrintBase64")
        if not b64:
            continue
        raw = base64.b64decode(b64)
        count = len(raw) // 4
        vectors.append(list(struct.unpack(f"<{count}f", raw[:count * 4])))
        labels.append(example["label"])

    if not vectors:
        raise SystemExit("Aucune empreinte dans l'export (photos sans featurePrint).")

    dimension = len(vectors[0])
    vectors = [v for v in vectors if len(v) == dimension]

    builder = KNearestNeighborsClassifierBuilder(
        input_name="featurePrint",
        output_name="label",
        number_of_dimensions=dimension,
        default_class_label="inconnu",
        number_of_neighbors=5,
        weighting_scheme="inverse_distance",
        index_type="linear",
    )
    builder.add_samples(vectors, labels)
    builder.is_updatable = True
    builder.description = "kNN personnel Jardin Intelligent (empreintes Vision, updatable)"

    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / "PersonalPlantKNN.mlmodel"
    ct.models.MLModel(builder.spec).save(str(out_path))
    return out_path


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--export", type=Path, required=True,
                        help="dossier JardinApprentissage-<date> exporté par l'app")
    parser.add_argument("--data-dir", type=Path, default=Path("datasets"))
    parser.add_argument("--out", type=Path, default=Path("output"))
    parser.add_argument("--epochs", type=int, default=8)
    parser.add_argument("--knn", action="store_true",
                        help="construire aussi le modèle kNN updatable")
    parser.add_argument("--skip-training", action="store_true",
                        help="fusionner le dataset sans réentraîner")
    args = parser.parse_args()

    copied = merge_into_dataset(args.export, args.data_dir)
    print(f"{copied} image(s) fusionnée(s) dans {args.data_dir}/")

    if args.knn:
        knn_path = build_updatable_knn(args.export, args.out)
        print(f"Modèle kNN updatable : {knn_path}")

    if not args.skip_training:
        script = Path(__file__).parent / "train_initial_classifier.py"
        subprocess.run([sys.executable, str(script),
                        "--data-dir", str(args.data_dir),
                        "--out", str(args.out),
                        "--epochs", str(args.epochs)], check=True)


if __name__ == "__main__":
    main()
