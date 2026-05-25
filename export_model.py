from ultralytics import YOLO
from huggingface_hub import hf_hub_download

print("Downloading model...")
model_path = hf_hub_download(
    repo_id="mustafakemal0146/playing-cards-yolov8",
    filename="playing_cards_model_0_playing-cards-colab.pt"
)

print(f"Loading model from {model_path}...")
model = YOLO(model_path)

print("Exporting to ONNX format...")
model.export(format='onnx', imgsz=640)
print("✓ Model exported to ONNX")
