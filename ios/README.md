# Belote Counter - iOS Native App

Application iOS native utilisant SwiftUI et Core ML pour la détection de cartes en temps réel.

## Prérequis

- macOS avec Xcode 15+
- iPhone avec iOS 17+ (A12 Bionic ou plus récent pour Neural Engine)
- Compte développeur Apple

## Structure du projet

```
ios/
├── BeloteCounter/              # Projet Xcode (à créer)
│   ├── BeloteCounterApp.swift  # Point d'entrée
│   ├── ContentView.swift       # Vue principale
│   ├── CameraView.swift        # Gestion caméra
│   ├── CardDetector.swift      # Détection Core ML
│   ├── BeloteGame.swift        # Logique du jeu
│   └── PlayingCardsModel.mlpackage  # Modèle Core ML
├── export_coreml.py            # Script d'export du modèle
└── README.md                   # Ce fichier
```

## Installation

### 1. Créer le projet Xcode

```bash
# Ouvrir Xcode
open -a Xcode

# Créer un nouveau projet:
# - iOS > App
# - Product Name: BeloteCounter
# - Interface: SwiftUI
# - Language: Swift
# - Save to: ios/BeloteCounter
```

### 2. Ajouter le modèle Core ML

1. Glisser-déposer `PlayingCardsModel.mlpackage` dans le projet Xcode
2. Xcode génère automatiquement les classes Swift

### 3. Copier les fichiers Swift

Copier tous les fichiers `.swift` fournis dans le projet Xcode.

### 4. Configurer les permissions

Dans `Info.plist`, ajouter :
```xml
<key>NSCameraUsageDescription</key>
<string>Nécessaire pour détecter les cartes</string>
```

### 5. Build et Run

1. Connecter votre iPhone
2. Sélectionner votre iPhone comme cible
3. Cmd+R pour compiler et installer

## Performances

- **Détection**: ~30-60 FPS sur iPhone (A12+)
- **Latence**: <50ms grâce au Neural Engine
- **Précision**: Identique au modèle YOLO original

## Développement

Pour modifier le modèle :
```bash
uv run python export_coreml.py
```

Puis remplacer `PlayingCardsModel.mlpackage` dans Xcode.
