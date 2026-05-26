#!/usr/bin/env python3
"""
Export YOLO model to Core ML format for iOS deployment
"""
import sys
sys.path.insert(0, '..')

from ultralytics import YOLO
from huggingface_hub import hf_hub_download

print("📦 Downloading YOLO model from HuggingFace...")
model_path = hf_hub_download(
    repo_id="mustafakemal0146/playing-cards-yolov8",
    filename="playing_cards_model_0_playing-cards-colab.pt"
)

print(f"✓ Model downloaded: {model_path}")

print("\n🔄 Loading model...")
model = YOLO(model_path)

print("\n🚀 Exporting to Core ML format...")
print("   This will create a .mlpackage optimized for iOS Neural Engine")

# Export to Core ML
# nms=True includes Non-Maximum Suppression in the model
model.export(format='coreml', nms=True, imgsz=640)

print("\n✅ Export complete!")
print("   Model saved as a .mlpackage directory")
print("   Add it to your Xcode project:")
print("   1. Drag the .mlpackage folder into Xcode")
print("   2. Xcode will automatically generate Swift classes")
