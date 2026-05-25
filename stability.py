class StabilityChecker:
    def __init__(self, stability_frames=15):
        self.stability_frames = stability_frames
        self.frame_count = 0
        self.last_class_name = None
        self.validated_this_cycle = None
        self.all_validated_cards = set()

    def track(self, detections):
        if not detections:
            self.frame_count = 0
            self.last_class_name = None
            return None

        best_detection = max(detections, key=lambda d: d["confidence"])
        current_class_name = best_detection["class_name"]

        if current_class_name == self.last_class_name:
            self.frame_count += 1
        else:
            self.frame_count = 1
            self.last_class_name = current_class_name
            self.validated_this_cycle = None

        if self.frame_count >= self.stability_frames:
            if self.validated_this_cycle is None:
                self.validated_this_cycle = current_class_name
                is_new_card = current_class_name not in self.all_validated_cards
                self.all_validated_cards.add(current_class_name)
                return {"card": current_class_name, "is_new": is_new_card}

        return None

    def reset(self):
        self.frame_count = 0
        self.last_class_name = None
        self.validated_this_cycle = None
        self.all_validated_cards.clear()
