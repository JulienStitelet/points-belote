import cv2
import os
import platform

VALUE_NAMES = {
    "J": "Valet",
    "Q": "Dame",
    "K": "Roi",
    "A": "As",
}

SUIT_NAMES = {
    "C": "Trèfle",
    "D": "Carreau",
    "H": "Coeur",
    "S": "Pique",
}

MODE_DISPLAY = {
    "ATOUT_COEUR": "ATOUT COEUR",
    "ATOUT_PIQUE": "ATOUT PIQUE",
    "ATOUT_CARREAU": "ATOUT CARREAU",
    "ATOUT_TREFLE": "ATOUT TREFLE",
    "SANS_ATOUT": "SANS ATOUT",
    "TOUT_ATOUT": "TOUT ATOUT",
}


def play_card_sound():
    system = platform.system()
    try:
        if system == "Darwin":
            os.system("afplay /System/Library/Sounds/Glass.aiff 2>/dev/null &")
        elif system == "Windows":
            import winsound
            winsound.Beep(1000, 200)
        elif system == "Linux":
            os.system("paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null &")
    except:
        pass


def play_points_sound():
    system = platform.system()
    try:
        if system == "Darwin":
            os.system("afplay /System/Library/Sounds/Ping.aiff 2>/dev/null &")
        elif system == "Windows":
            import winsound
            winsound.Beep(800, 300)
        elif system == "Linux":
            os.system("paplay /usr/share/sounds/freedesktop/stereo/positive.oga 2>/dev/null &")
    except:
        pass


def card_name_readable(class_name):
    if len(class_name) < 2:
        return class_name

    value = class_name[:-1]
    suit = class_name[-1]

    value_str = VALUE_NAMES.get(value, value)
    suit_str = SUIT_NAMES.get(suit, suit)

    return f"{value_str} de {suit_str}"
    suit_str = SUIT_NAMES.get(suit, suit)

    return f"{value_str} de {suit_str}"


def render(frame, detections, game, last_card=None, last_card_time=None):
    h, w = frame.shape[:2]
    overlay = frame.copy()

    for detection in detections:
        bbox = detection["bbox"]
        x1, y1, x2, y2 = bbox
        color = (0, 255, 0)
        cv2.rectangle(overlay, (x1, y1), (x2, y2), color, 2)

    cv2.addWeighted(overlay, 0.9, frame, 0.1, 0, frame)

    points_text = f"Points: {game.total_points}  |  Cartes: {len(game.cards_played)}/32"
    text_size = cv2.getTextSize(points_text, cv2.FONT_HERSHEY_SIMPLEX, 2.1, 3)[0]
    points_x = (w - text_size[0]) // 2
    cv2.putText(
        frame,
        points_text,
        (points_x, 60),
        cv2.FONT_HERSHEY_SIMPLEX,
        2.1,
        (255, 255, 255),
        3,
    )

    if game.mode:
        mode_text = MODE_DISPLAY.get(game.mode, game.mode)
        cv2.putText(
            frame, mode_text, (10, 50), cv2.FONT_HERSHEY_SIMPLEX, 2.1, (0, 255, 0), 3
        )
    else:
        cv2.putText(
            frame,
            "-- Choisissez un mode --",
            (10, 50),
            cv2.FONT_HERSHEY_SIMPLEX,
            2.1,
            (0, 165, 255),
            3,
        )

    if not game.is_ready:
        overlay = frame.copy()
        cv2.rectangle(overlay, (0, 0), (w, h), (0, 0, 0), -1)
        cv2.addWeighted(overlay, 0.6, frame, 0.4, 0, frame)
        text = "Choisissez un mode pour commencer (touches 1 a 6)"
        cv2.putText(
            frame,
            text,
            (w // 4, h // 2),
            cv2.FONT_HERSHEY_SIMPLEX,
            1.8,
            (0, 165, 255),
            3,
        )

    shortcuts = "1-4: Atout  5: Sans  6: Tout  R: Reset  Q: Quitter"
    cv2.putText(
        frame,
        shortcuts,
        (10, h - 20),
        cv2.FONT_HERSHEY_SIMPLEX,
        1.5,
        (200, 200, 200),
        2,
    )

    if last_card:
        card_readable = card_name_readable(last_card["name"])
        points = last_card["points"]
        display_text = f"✓ {card_readable} (+{points}pts)"
        text_size = cv2.getTextSize(display_text, cv2.FONT_HERSHEY_SIMPLEX, 1.8, 2)[0]
        text_x = (w - text_size[0]) // 2
        text_y = h - 100
        cv2.putText(
            frame,
            display_text,
            (text_x, text_y),
            cv2.FONT_HERSHEY_SIMPLEX,
            1.8,
            (0, 255, 0),
            3,
        )

    return frame
