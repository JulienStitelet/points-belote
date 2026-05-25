from ultralytics import YOLO
from huggingface_hub import hf_hub_download


class CardDetector:
    def __init__(self):
        model_path = hf_hub_download(
            repo_id="mustafakemal0146/playing-cards-yolov8",
            filename="playing_cards_model_0_playing-cards-colab.pt",
        )
        self.model = YOLO(model_path)

    def detect(self, frame):
        """
        Detect cards in frame using YOLO.
        Returns list of {class_name, confidence, bbox}
        """
        results = self.model(frame, verbose=False)
        detections = []

        for result in results:
            for box in result.boxes:
                confidence = float(box.conf[0])
                if confidence > 0.75:
                    class_id = int(box.cls[0])
                    class_name = result.names[class_id]

                    x1, y1, x2, y2 = box.xyxy[0]
                    bbox = (int(x1), int(y1), int(x2), int(y2))

                    detections.append(
                        {
                            "class_name": class_name,
                            "confidence": confidence,
                            "bbox": bbox,
                        }
                    )

        return self._merge_nearby_detections(detections)

    def _merge_nearby_detections(self, detections, distance_threshold=200):
        if not detections:
            return detections

        merged = []
        used = set()

        for i, det1 in enumerate(detections):
            if i in used:
                continue

            cluster = [det1]
            used.add(i)

            for j, det2 in enumerate(detections[i + 1 :], start=i + 1):
                if j in used:
                    continue

                if det1["class_name"] == det2["class_name"]:
                    center1 = self._bbox_center(det1["bbox"])
                    center2 = self._bbox_center(det2["bbox"])
                    dist = self._distance(center1, center2)

                    if dist < distance_threshold:
                        cluster.append(det2)
                        used.add(j)

            merged.append(self._merge_cluster(cluster))

        return merged

    def _bbox_center(self, bbox):
        x1, y1, x2, y2 = bbox
        return ((x1 + x2) // 2, (y1 + y2) // 2)

    def _distance(self, p1, p2):
        return ((p1[0] - p2[0]) ** 2 + (p1[1] - p2[1]) ** 2) ** 0.5

    def _merge_cluster(self, cluster):
        if len(cluster) == 1:
            return cluster[0]

        avg_confidence = sum(d["confidence"] for d in cluster) / len(cluster)
        bboxes = [d["bbox"] for d in cluster]

        x1 = min(b[0] for b in bboxes)
        y1 = min(b[1] for b in bboxes)
        x2 = max(b[2] for b in bboxes)
        y2 = max(b[3] for b in bboxes)

        return {
            "class_name": cluster[0]["class_name"],
            "confidence": avg_confidence,
            "bbox": (x1, y1, x2, y2),
        }
