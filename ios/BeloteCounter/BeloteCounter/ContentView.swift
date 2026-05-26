import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var game = BeloteGame()
    @State private var detections: [Detection] = []
    @State private var showModeSelector = true
    @State private var validatedCards = Set<String>()

    private let detector = CardDetector()
    private var frameSkipCounter = 0

    // Audio players for custom sounds (by point value)
    @State private var audioPlayers: [String: AVAudioPlayer] = [:]

    // Stability tracking
    @State private var lastDetectedCard: String?
    @State private var consecutiveFrames = 0
    private let stabilityFramesRequired = 5  // Require 5 consecutive frames

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
                                }) {
                                    Text("🔄 Reset")
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }

                                Button(action: {
                                    showModeSelector = true
                                    game.reset()
                                    validatedCards.removeAll()
                                }) {
                                    Text("🎯 Changer Mode")
                                        .padding()
                                        .background(Color.orange)
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
                            let points = game.addCard(cardClass)

                            // Play sound feedback based on points
                            playSoundForPoints(points)

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
            "sound_0",    // 0 points
            "sound_10",   // 10 points
            "sound_11",   // 11 points (As)
            "sound_14",   // 14 points (9 d'atout)
            "sound_20",   // 20 points (Valet d'atout)
            "sound_low"   // Points faibles (Roi, Dame)
        ]

        for soundName in soundFiles {
            if let path = Bundle.main.path(forResource: soundName, ofType: "wav") {
                let url = URL(fileURLWithPath: path)
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    audioPlayers[soundName] = player
                    print("✅ Loaded \(soundName).wav")
                } catch {
                    print("❌ Failed to load \(soundName).wav: \(error)")
                }
            }
        }
    }

    private func playSoundForPoints(_ points: Int) {
        let soundName: String

        switch points {
        case 0:
            soundName = "sound_0"
        case 10:
            soundName = "sound_10"
        case 11:
            soundName = "sound_11"
        case 14:
            soundName = "sound_14"
        case 20:
            soundName = "sound_20"
        case 1...4:
            soundName = "sound_low"  // Roi, Dame, 8, 7
        default:
            soundName = "sound_low"  // Fallback
        }

        if let player = audioPlayers[soundName] {
            player.currentTime = 0
            player.play()
        }
    }
}

struct ModeSelectorView: View {
    let selectedMode: (BeloteMode) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Choisissez un mode")
                .font(.largeTitle)
                .padding()

            ForEach(BeloteMode.allCases, id: \.self) { mode in
                Button(action: {
                    selectedMode(mode)
                }) {
                    Text(mode.displayName)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
