POINTS = {
    "J": [20, 2, 2, 20],
    "9": [14, 0, 0, 14],
    "A": [11, 11, 11, 11],
    "10": [10, 10, 10, 10],
    "K": [4, 4, 4, 4],
    "Q": [3, 3, 3, 3],
    "8": [0, 0, 0, 0],
    "7": [0, 0, 0, 0],
}

MODES = {
    "ATOUT_COEUR": 0,
    "ATOUT_PIQUE": 1,
    "ATOUT_CARREAU": 2,
    "ATOUT_TREFLE": 3,
    "SANS_ATOUT": 4,
    "TOUT_ATOUT": 5,
}

SUIT_MAP = {"C": "C", "D": "D", "H": "H", "S": "S"}
ATOUT_SUITS = {
    "ATOUT_COEUR": "H",
    "ATOUT_PIQUE": "S",
    "ATOUT_CARREAU": "D",
    "ATOUT_TREFLE": "C",
}


class BeloteGame:
    def __init__(self):
        self.mode = None
        self.is_ready = False
        self.total_points = 0
        self.cards_played = []
        self.counted_cards = set()

    def set_mode(self, mode: str):
        self.mode = mode
        self.is_ready = True

    def get_points(self, class_name: str) -> int:
        if len(class_name) < 2:
            return 0

        value = class_name[:-1]
        suit = class_name[-1]

        if value not in POINTS:
            return 0

        points_row = POINTS[value]

        if self.mode == "SANS_ATOUT":
            return points_row[2]
        elif self.mode == "TOUT_ATOUT":
            return points_row[3]
        elif self.mode in ATOUT_SUITS:
            atout_suit = ATOUT_SUITS[self.mode]
            if suit == atout_suit:
                return points_row[0]
            else:
                return points_row[1]

        return 0

    def add_card(self, class_name: str) -> int:
        if class_name in self.counted_cards:
            return 0

        points = self.get_points(class_name)
        self.total_points += points
        self.cards_played.append(class_name)
        self.counted_cards.add(class_name)
        return points

    def reset(self):
        self.total_points = 0
        self.cards_played = []
        self.counted_cards.clear()
