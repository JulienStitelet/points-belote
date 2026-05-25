# Belote Counter - iPhone PWA

Version Progressive Web App pour iPhone du compteur de points Belote.

## Installation

### 1. Exporter le modèle YOLO en ONNX

Depuis la racine du projet :

```bash
uv run python iphone/export_model.py
```

Cela va générer `model.onnx` que vous devez placer dans `iphone/`.

### 2. Servir l'application

L'app doit être servie via HTTPS pour accéder à la caméra. Options :

**Option A : Serveur local simple**
```bash
cd iphone
python -m http.server 8000
```

Puis accéder via : `http://localhost:8000`

**Option B : Serveur HTTPS avec certificat auto-signé**
```bash
cd iphone
# Installer mkcert (macOS)
brew install mkcert
mkcert -install
mkcert localhost

# Servir avec HTTPS
python -m http.server 8000 --bind localhost
```

**Option C : Déployer sur GitHub Pages / Netlify / Vercel**

Le plus simple pour tester sur iPhone réel.

### 3. Installer sur iPhone

1. Ouvrir Safari sur iPhone
2. Aller sur l'URL de l'app
3. Appuyer sur le bouton "Partager" (carré avec flèche)
4. Sélectionner "Sur l'écran d'accueil"
5. L'app s'ouvre en mode standalone

## Structure

```
iphone/
├── index.html          # Interface PWA
├── app.js              # Logique du jeu (Belote rules)
├── detector.js         # Détection YOLO via ONNX Runtime Web
├── style.css           # Style iPhone-optimized
├── manifest.json       # PWA manifest
├── sw.js               # Service worker (offline support)
├── model.onnx          # Modèle YOLO exporté (à générer)
├── export_model.py     # Script d'export ONNX
└── README.md           # Ce fichier
```

## Fonctionnalités

✅ Détection de cartes via caméra en temps réel
✅ Calcul automatique des points (6 modes Belote)
✅ Audio feedback (sons différents pour détection vs points)
✅ Interface tactile optimisée iPhone
✅ Mode PWA installable
✅ Support offline (service worker)

## Contrôles

- **Sélection mode** : Touch sur le bouton du mode désiré
- **Reset** : Bouton 🔄 en bas de l'écran
- **Changer mode** : Bouton 🎯 en bas de l'écran

## Notes techniques

- **ONNX Runtime Web** : Exécute YOLO directement dans le navigateur
- **WebRTC** : Accès caméra arrière iPhone
- **Web Audio API** : Sons de feedback
- **Canvas API** : Overlay de détection

## Limitations

- Nécessite HTTPS pour la caméra
- Performance dépend de l'iPhone (A12+ recommandé)
- Modèle ONNX (~6MB) à télécharger au premier lancement

## Développement

Pour modifier :

1. Éditer les fichiers dans `iphone/`
2. Recharger la page (Cmd+R sur Safari)
3. Vider le cache si nécessaire (Réglages > Safari > Effacer données)
