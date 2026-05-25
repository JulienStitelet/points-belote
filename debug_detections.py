import cv2
from detector import CardDetector

detector = CardDetector()
cap = cv2.VideoCapture(0)

if not cap.isOpened():
    cap = cv2.VideoCapture(1)

if not cap.isOpened():
    print("Webcam not available")
    exit()

print("Debug Mode: Affichage des détections brutes du modèle")
print("Appuyez sur Q pour quitter\n")

frame_count = 0
while True:
    ret, frame = cap.read()
    if not ret:
        break

    detections = detector.detect(frame)

    # Draw all detections (raw, unfiltered)
    h, w = frame.shape[:2]
    for i, det in enumerate(detections):
        bbox = det["bbox"]
        x1, y1, x2, y2 = bbox

        color = (0, 255, 0) if det["confidence"] > 0.85 else (0, 165, 255)
        cv2.rectangle(frame, (x1, y1), (x2, y2), color, 2)

        label = f"{det['class_name']} {det['confidence']:.2f}"
        cv2.putText(frame, label, (x1, y1 - 5), cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 1)

    # Show info
    cv2.putText(
        frame,
        f"Detections: {len(detections)}",
        (10, 30),
        cv2.FONT_HERSHEY_SIMPLEX,
        0.7,
        (255, 255, 255),
        2,
    )

    frame_count += 1
    if frame_count % 30 == 0:
        print(f"Frame {frame_count}: {len(detections)} detections")
        if len(detections) > 0:
            print(f"  {[d['class_name'] for d in detections[:5]]}")

    cv2.imshow("Debug - Raw Detections", frame)

    if cv2.waitKey(1) & 0xFF == ord("q"):
        break

cap.release()
cv2.destroyAllWindows()
print("Done")
