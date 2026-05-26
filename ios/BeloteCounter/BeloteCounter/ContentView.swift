import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var game = BeloteGame()
    @State private var detections: [Detection] = []
    @State private var showModeSelector = true
    @State private var validatedCards = Set<String>()

    private let detector = CardDetector()
    private var frameSkipCounter = 0

    // Audio players for spoken card-name sounds
    @State private var audioPlayers: [String: AVAudioPlayer] = [:]

    // Stability tracking
    @State private var lastDetectedCard: String?
    @State private var consecutiveFrames = 0
    private let stabilityFramesRequired = 5  // Require 5 consecutive frames

    // Fires 2s after the last detection to announce the running total
    @State private var silenceTimer: Timer?
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    private let silenceInterval: TimeInterval = 2.0

    var body: some View {
        ZStack {
            if showModeSelector {
                // Mode selection screen
                ModeSelectorView(selectedMode: { mode in
                    game.setMode(mode)
                    showModeSelector = false
                })
            } else {
                // Game view
                GeometryReader { geometry in
                    ZStack(alignment: .top) {
                        // Camera feed with detections
                        CameraView(detections: $detections) { pixelBuffer in
                            handleFrame(pixelBuffer)
                        }
                        .edgesIgnoringSafeArea(.all)

                        VStack(spacing: 0) {
                            // Score bar
                            HStack {
                                Text("Points: \(game.totalPoints)")
                                Spacer()
                                Text("Cartes: \(game.cardsPlayed.count)/32")
                            }
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .font(.headline)

                            Spacer()

                            // Last card notification
                            if let lastCard = game.lastCard {
                                Text("✓ \(game.cardReadableName(lastCard.name)) (+\(lastCard.points)pts)")
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .transition(.scale)
                                    .padding(.bottom, 120)
                            }

                            Spacer()

                            // Controls
                            HStack(spacing: 20) {
                                Button(action: {
                                    game.reset()
                                    validatedCards.removeAll()
                                    silenceTimer?.invalidate()
                                    silenceTimer = nil
                                }) {
                                    Text("🔄 Reset")
                                        .padding()
                                        .background(Color(red: 230/255, green: 57/255, blue: 70/255))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }

                                Button(action: {
                                    showModeSelector = true
                                    game.reset()
                                    validatedCards.removeAll()
                                    silenceTimer?.invalidate()
                                    silenceTimer = nil
                                }) {
                                    Text("🎯 Changer Mode")
                                        .padding()
                                        .background(Color(red: 242/255, green: 100/255, blue: 25/255))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            }
                            .padding()
                        }

                        // Mode display
                        if let mode = game.mode {
                            Text(mode.displayName)
                                .padding(8)
                                .background(Color.black.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .padding(.top, 100)
                        }
                    }
                }
            }
        }
        .onAppear {
            requestCameraPermission()
            loadAudioFiles()
        }
    }

    private func handleFrame(_ pixelBuffer: CVPixelBuffer) {
        guard game.isReady else { return }

        detector.detect(image: pixelBuffer) { newDetections in
            DispatchQueue.main.async {
                self.detections = newDetections

                // Process the best detection with stability check
                if let bestDetection = newDetections.first {
                    let cardClass = bestDetection.className

                    // Cards are visible — push the total announcement back
                    scheduleTotalAnnouncement()

                    // Check if same card detected consecutively
                    if cardClass == lastDetectedCard {
                        consecutiveFrames += 1
                    } else {
                        // Different card, reset counter
                        lastDetectedCard = cardClass
                        consecutiveFrames = 1
                    }

                    // Only validate if stable for required frames
                    if consecutiveFrames >= stabilityFramesRequired {
                        if !validatedCards.contains(cardClass) {
                            validatedCards.insert(cardClass)
                            _ = game.addCard(cardClass)

                            // Per-card name wav (kept commented in case we want it back)
                            // playSoundForCard(cardClass)

                            // Speak the running total after each card
                            speakRunningTotal()

                            // Reset stability after validation
                            lastDetectedCard = nil
                            consecutiveFrames = 0
                        }
                    }
                } else {
                    // No detection, reset
                    lastDetectedCard = nil
                    consecutiveFrames = 0
                }
            }
        }
    }

    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if !granted {
                print("❌ Camera permission denied")
            }
        }
    }

    private func loadAudioFiles() {
        let soundFiles = [
            "sept", "huit", "neuf", "dix",
            "valet", "dame", "roi", "as",
            "quatorze", "vingt",
            "belote", "rebelote"
        ]

        print("🔊 Loading audio files...")
        for soundName in soundFiles {
            if let path = Bundle.main.path(forResource: soundName, ofType: "wav") {
                let url = URL(fileURLWithPath: path)
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.enableRate = true
                    player.rate = 1.2
                    player.prepareToPlay()
                    audioPlayers[soundName] = player
                    print("✅ Loaded \(soundName).wav")
                } catch {
                    print("❌ Failed to load \(soundName).wav: \(error)")
                }
            } else {
                print("⚠️ File not found in bundle: \(soundName).wav")
            }
        }
        print("🔊 Total loaded: \(audioPlayers.count)/\(soundFiles.count)")
    }

    private func soundName(for cardClass: String) -> String? {
        guard cardClass.count >= 2 else { return nil }
        let value = String(cardClass.dropLast())
        let suit = String(cardClass.last!)
        let isAtout = game.mode?.atoutSuit == suit

        // Atout-only point announcements
        if isAtout {
            if value == "9" { return "quatorze" }
            if value == "J" { return "vingt" }
        }

        switch value {
        case "7": return "sept"
        case "8": return "huit"
        case "9": return "neuf"
        case "10": return "dix"
        case "J": return "valet"
        case "Q": return "dame"
        case "K": return "roi"
        case "A": return "as"
        default: return nil
        }
    }

    private func playSoundForCard(_ cardClass: String) {
        guard let name = soundName(for: cardClass) else {
            print("⚠️ No sound mapped for \(cardClass)")
            return
        }

        print("🎵 Playing \(name) for \(cardClass)")

        if let player = audioPlayers[name] {
            player.currentTime = 0
            player.play()
        } else {
            print("❌ No player found for \(name)")
        }
    }

    private func scheduleTotalAnnouncement() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceInterval, repeats: false) { _ in
            emitTotalPoints()
        }
    }

    private func emitTotalPoints() {
        guard !game.cardsPlayed.isEmpty else { return }

        let cardsTotal = game.totalPoints
        let beloteBonus = beloteRebeloteCount * 20
        let grandTotal = cardsTotal + beloteBonus

        let text: String
        if beloteBonus > 0 {
            text = "\(cardsTotal) points plus \(beloteBonus) points de belote rebelote égale \(grandTotal) points"
        } else {
            text = "\(cardsTotal) points"
        }

        print("🗣 Announcing total: \(text)")
        speak(text)
    }

    private func speakRunningTotal() {
        // Interrupt any in-flight utterance so rapid scans don't pile up
        speechSynthesizer.stopSpeaking(at: .immediate)
        speak("\(game.totalPoints)")
    }

    private func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "fr-FR")
        utterance.rate = 0.52           // snappy scan feedback (default 0.5)
        utterance.pitchMultiplier = 1.15
        speechSynthesizer.speak(utterance)
    }

    private var beloteRebeloteCount: Int {
        guard let mode = game.mode else { return 0 }
        let atoutSuits: [String]
        switch mode {
        case .atoutCoeur:   atoutSuits = ["H"]
        case .atoutPique:   atoutSuits = ["S"]
        case .atoutCarreau: atoutSuits = ["D"]
        case .atoutTrefle:  atoutSuits = ["C"]
        case .toutAtout:    atoutSuits = ["H", "S", "D", "C"]
        case .sansAtout:    atoutSuits = []
        }
        return atoutSuits.filter { suit in
            validatedCards.contains("K\(suit)") && validatedCards.contains("Q\(suit)")
        }.count
    }
}

struct ModeSelectorView: View {
    let selectedMode: (BeloteMode) -> Void

    var body: some View {
        ZStack {
            // Background color #0B132B
            Color(red: 11/255, green: 19/255, blue: 43/255)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Choisissez un mode")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 2)
                    .padding()

                ForEach(BeloteMode.allCases, id: \.self) { mode in
                    Button(action: {
                        selectedMode(mode)
                    }) {
                        Text(mode.displayName)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 242/255, green: 100/255, blue: 25/255))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
