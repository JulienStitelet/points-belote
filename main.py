import cv2
import time
from detector import CardDetector
from stability import StabilityChecker
from belote import BeloteGame
from display import render, play_card_sound, play_points_sound


def main():
    detector = CardDetector()
    stability = StabilityChecker(stability_frames=2)
    game = BeloteGame()

    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        cap = cv2.VideoCapture(1)

    if not cap.isOpened():
        print("Error: Could not open webcam")
        return

    last_card = None
    last_card_time = None

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        detections = []
        if game.is_ready:
            detections = detector.detect(frame)
            result = stability.track(detections)
            if result:
                card = result["card"]
                is_new = result["is_new"]
                points = game.add_card(card)

                if points > 0:
                    last_card = {"name": card, "points": points}
                    last_card_time = time.time()
                    play_card_sound()
                elif is_new:
                    play_points_sound()

        if last_card_time and time.time() - last_card_time > 2:
            last_card = None
            last_card_time = None

        rendered = render(frame, detections, game, last_card, last_card_time)
        cv2.imshow("Belote Counter", rendered)

        key = cv2.waitKey(1) & 0xFF
        if key == ord("q"):
            break
        elif key == ord("1"):
            game.set_mode("ATOUT_COEUR")
            stability.reset()
        elif key == ord("2"):
            game.set_mode("ATOUT_PIQUE")
            stability.reset()
        elif key == ord("3"):
            game.set_mode("ATOUT_CARREAU")
            stability.reset()
        elif key == ord("4"):
            game.set_mode("ATOUT_TREFLE")
            stability.reset()
        elif key == ord("5"):
            game.set_mode("SANS_ATOUT")
            stability.reset()
        elif key == ord("6"):
            game.set_mode("TOUT_ATOUT")
            stability.reset()
        elif key == ord("r"):
            game.reset()
            stability.reset()

    cap.release()
    cv2.destroyAllWindows()


if __name__ == "__main__":
    main()
