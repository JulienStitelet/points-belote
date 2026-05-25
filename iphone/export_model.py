#!/usr/bin/env python3
"""
Export YOLO model to ONNX format for web deployment
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

print("\n🚀 Exporting to ONNX format...")
model.export(format='onnx', imgsz=640, simplify=True)

print("\n✅ Export complete!")
print("   Model saved as: model.onnx")
print("   Move it to iphone/ directory:")
print("   $ mv model.onnx iphone/")
