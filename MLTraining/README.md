# MLTraining — modèle Core ML de Jardin Intelligent

L'app fonctionne **sans aucun modèle à entraîner** : la reconnaissance repose alors
sur la taxonomie Vision d'Apple, le classifieur personnel kNN (photos de
l'utilisateur) et, en option, une API en ligne. Ce dossier sert à produire le
**modèle embarqué** qui renforce l'étage 2 du pipeline.

## 1. Entraîner le modèle initial

### Option A — Create ML (sans Python)
1. Ouvrir l'app **Create ML** (livrée avec Xcode) → *Image Classification*.
2. Glisser un dataset « un dossier par classe » (voir datasets ci-dessous).
3. Activer les augmentations (rotation, flou, exposition), entraîner.
4. Exporter `PlantClassifier.mlmodel` et l'ajouter à la cible Xcode.

### Option B — PyTorch (ce dossier)
```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# organiser le dataset : datasets/<classe>/*.jpg  (ex : tomate/, tomate_mildiou/, basilic/)
python3 train_initial_classifier.py --data-dir datasets --epochs 8 --out output/
```
Sortie : `output/PlantClassifier.mlpackage` → le glisser dans la cible
`JardinIntelligent` d'Xcode. `BundledCoreMLIdentifier` le charge automatiquement
au prochain lancement (aucun code à changer).

### Datasets publics
| Dataset | Contenu | Lien |
|---|---|---|
| PlantVillage | 54 000 photos de feuilles, 38 classes espèce+maladie | github.com/spMohanty/PlantVillage-Dataset |
| Pl@ntNet-300K | 306 000 photos, 1 081 espèces | zenodo.org/records/5645731 |
| iNaturalist | photos naturalistes sous licences CC (API d'export) | inaturalist.org |

Conseils de classes : mélanger espèces (`tomate`, `basilic`…) et états
(`tomate_mildiou`, `courgette_oidium`, `feuilles_jaunes`) — l'app affiche le
label tel quel (underscores remplacés par des espaces).

## 2. Apprentissage continu

Deux mécanismes complémentaires :

1. **Dans l'app, immédiat** : chaque identification validée/corrigée stocke une
   *empreinte Vision* (vecteur) + la photo dans `LearningExample`. Le classifieur
   kNN personnel (`PersonalPlantClassifier`) l'utilise dès la photo suivante —
   aucun réentraînement, tout reste sur l'appareil, synchronisé via iCloud.

2. **Hors app, périodique** : réentraîner le modèle embarqué avec les données
   utilisateur exportées (Réglages → *Exporter le dataset*) :

```bash
python3 retrain_from_export.py --export ~/Downloads/JardinApprentissage-2026-07-16 \
    --data-dir datasets --epochs 8
```
Le script fusionne les photos dans le dataset (les **corrections** utilisateur
sont sur-échantillonnées ×2), relance l'entraînement et produit un nouveau
`PlantClassifier.mlpackage` à remettre dans Xcode.

### Variante : kNN Core ML updatable
```bash
python3 retrain_from_export.py --export <dossier> --knn --skip-training
```
produit `PersonalPlantKNN.mlmodel` (updatable via `MLUpdateTask`), si vous
préférez la mise à jour on-device orchestrée par Core ML au kNN Swift intégré.

## 3. Format d'export de l'app

```
JardinApprentissage-<date>/
├── manifest.json          # version, date, exemples[]
└── images/<uuid>.jpg
```
Chaque exemple : `id`, `label`, `tags[]`, `source`
(`identification`/`correction`/`manuelle`), `createdAt`, `imageFile`,
`featurePrintBase64` (vecteur float32 little-endian de l'empreinte Vision).
L'import (Réglages → *Importer un dataset*) est idempotent (fusion par id).
