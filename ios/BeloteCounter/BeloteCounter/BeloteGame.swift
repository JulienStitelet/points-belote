import Foundation

// MARK: - Game Mode
enum BeloteMode: String, CaseIterable {
    case atoutCoeur = "ATOUT_COEUR"
    case atoutPique = "ATOUT_PIQUE"
    case atoutCarreau = "ATOUT_CARREAU"
    case atoutTrefle = "ATOUT_TREFLE"
    case sansAtout = "SANS_ATOUT"
    case toutAtout = "TOUT_ATOUT"

    var displayName: String {
        switch self {
        case .atoutCoeur: return "♥️ Atout Coeur"
        case .atoutPique: return "♠️ Atout Pique"
        case .atoutCarreau: return "♦️ Atout Carreau"
        case .atoutTrefle: return "♣️ Atout Trèfle"
        case .sansAtout: return "Sans Atout"
        case .toutAtout: return "Tout Atout"
        }
    }

    var atoutSuit: String? {
        switch self {
        case .atoutCoeur: return "H"
        case .atoutPique: return "S"
        case .atoutCarreau: return "D"
        case .atoutTrefle: return "C"
        default: return nil
        }
    }
}

// MARK: - Points Table
struct CardPoints {
    static let points: [String: [Int]] = [
        "J": [20, 2, 2, 20],   // atout, non-atout, sans-atout, tout-atout
        "9": [14, 0, 0, 14],
        "A": [11, 11, 11, 11],
        "10": [10, 10, 10, 10],
        "K": [4, 4, 4, 4],
        "Q": [3, 3, 3, 3],
        "8": [0, 0, 0, 0],
        "7": [0, 0, 0, 0]
    ]
}

// MARK: - Belote Game
class BeloteGame: ObservableObject {
    @Published var mode: BeloteMode?
    @Published var totalPoints: Int = 0
    @Published var cardsPlayed: [String] = []
    @Published var countedCards: Set<String> = []
    @Published var lastCard: (name: String, points: Int)?

    var isReady: Bool {
        mode != nil
    }

    func setMode(_ newMode: BeloteMode) {
        mode = newMode
    }

    func getPoints(for className: String) -> Int {
        guard className.count >= 2 else { return 0 }

        let value = String(className.dropLast())
        let suit = String(className.last!)

        guard let pointsRow = CardPoints.points[value] else { return 0 }

        guard let currentMode = mode else { return 0 }

        switch currentMode {
        case .sansAtout:
            return pointsRow[2]
        case .toutAtout:
            return pointsRow[3]
        case .atoutCoeur, .atoutPique, .atoutCarreau, .atoutTrefle:
            if let atoutSuit = currentMode.atoutSuit, suit == atoutSuit {
                return pointsRow[0]  // atout
            } else {
                return pointsRow[1]  // non-atout
            }
        }
    }

    func addCard(_ className: String) -> Int {
        guard !countedCards.contains(className) else { return 0 }

        let points = getPoints(for: className)
        totalPoints += points
        cardsPlayed.append(className)
        countedCards.insert(className)

        if points > 0 {
            lastCard = (className, points)

            // Clear lastCard after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                if self?.lastCard?.name == className {
                    self?.lastCard = nil
                }
            }
        }

        return points
    }

    func reset() {
        totalPoints = 0
        cardsPlayed = []
        countedCards = []
        lastCard = nil
    }

    func cardReadableName(_ className: String) -> String {
        guard className.count >= 2 else { return className }

        let value = String(className.dropLast())
        let suit = String(className.last!)

        let valueNames: [String: String] = [
            "J": "Valet",
            "Q": "Dame",
            "K": "Roi",
            "A": "As"
        ]

        let suitNames: [String: String] = [
            "C": "Trèfle",
            "D": "Carreau",
            "H": "Coeur",
            "S": "Pique"
        ]

        let valueStr = valueNames[value] ?? value
        let suitStr = suitNames[suit] ?? suit

        return "\(valueStr) de \(suitStr)"
    }
}
