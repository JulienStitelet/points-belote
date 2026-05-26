# Guide d'installation - Belote Counter iOS

## Étape 1 : Créer le projet Xcode

1. Ouvrir Xcode
2. File > New > Project
3. Choisir "iOS" > "App"
4. Configuration :
   - **Product Name**: BeloteCounter
   - **Team**: Sélectionner votre compte développeur
   - **Organization Identifier**: com.votreidentifiant
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Storage**: None
   - **Include Tests**: Décoché
5. Sauvegarder dans : `/Users/jstitelet/dev/private/points-belote/ios/`

## Étape 2 : Ajouter les fichiers Swift

Dans Xcode :
1. Clic droit sur le dossier "BeloteCounter" (icône bleue)
2. "Add Files to BeloteCounter..."
3. Sélectionner tous les fichiers `.swift` :
   - BeloteCounterApp.swift
   - ContentView.swift
   - CameraView.swift
   - CardDetector.swift
   - BeloteGame.swift
4. Cocher "Copy items if needed"
5. Add

**Important** : Supprimer le `ContentView.swift` par défaut créé par Xcode pour éviter les doublons.

## Étape 3 : Ajouter le modèle Core ML

1. Glisser-déposer `PlayingCardsModel.mlpackage` dans le projet
2. Cocher "Copy items if needed" et "Add to targets: BeloteCounter"
3. Xcode compile automatiquement le modèle (fichier `.mlmodelc` généré)

## Étape 4 : Configurer les permissions

1. Ouvrir `Info.plist` (ou `Info` dans l'inspecteur)
2. Ajouter une nouvelle clé :
   - **Key**: Privacy - Camera Usage Description
   - **Type**: String
   - **Value**: "Nécessaire pour détecter les cartes de Belote"

Ou ajouter directement dans le fichier Info.plist :
```xml
<key>NSCameraUsageDescription</key>
<string>Nécessaire pour détecter les cartes de Belote</string>
```

## Étape 5 : Vérifier le Bundle Identifier

Dans les paramètres du projet :
1. Sélectionner la cible "BeloteCounter"
2. Onglet "Signing & Capabilities"
3. Vérifier que "Automatically manage signing" est coché
4. Vérifier que votre Team est sélectionné

## Étape 6 : Build et Run

### Sur Simulateur (pour tester l'interface uniquement)
1. Sélectionner un simulateur iPhone dans la liste
2. Cmd+R
3. **Note** : La caméra ne fonctionne pas sur simulateur

### Sur iPhone réel
1. Connecter votre iPhone via USB
2. Sélectionner votre iPhone dans la liste des devices
3. Sur l'iPhone : Réglages > Général > Gestion des appareils > Faire confiance au certificat
4. Cmd+R
5. Sur l'iPhone, autoriser l'accès à la caméra quand demandé

## Structure finale du projet Xcode

```
BeloteCounter/
├── BeloteCounter.xcodeproj
├── BeloteCounter/
│   ├── BeloteCounterApp.swift      # ✅ Ajouté
│   ├── ContentView.swift            # ✅ Ajouté (remplace le défaut)
│   ├── CameraView.swift             # ✅ Ajouté
│   ├── CardDetector.swift           # ✅ Ajouté
│   ├── BeloteGame.swift             # ✅ Ajouté
│   ├── PlayingCardsModel.mlpackage  # ✅ Ajouté
│   ├── Assets.xcassets
│   └── Info.plist                   # ✅ Modifié (camera permission)
```

## Troubleshooting

### Erreur : "Model file not found"
- Vérifier que `PlayingCardsModel.mlpackage` est bien dans le projet
- Vérifier que la cible "BeloteCounter" est cochée pour ce fichier

### Erreur de signature
- Aller dans Signing & Capabilities
- Changer le Bundle Identifier (ajouter votre préfixe)
- Sélectionner votre Team

### Caméra noire
- Vérifier les permissions dans Info.plist
- Sur l'iPhone : Réglages > BeloteCounter > Autoriser l'accès à la caméra

### Performance lente
- L'app doit tourner sur un iPhone A12+ pour bénéficier du Neural Engine
- Vérifier que le mode Release est utilisé (pas Debug)

## Performances attendues

- **iPhone 11 Pro et +** : 30-60 FPS, latence <50ms
- **iPhone X et antérieurs** : ~15-30 FPS (pas de Neural Engine)

## Alternative : Utiliser Xcode depuis GitHub

Si vous préférez, je peux créer un projet Xcode complet directement dans la branche et vous n'aurez qu'à l'ouvrir. Voulez-vous que je fasse ça ?
