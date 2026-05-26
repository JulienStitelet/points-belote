import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var game = BeloteGame()
    @State private var detections: [Detection] = []
    @State private var showModeSelector = true
    @State private var validatedCards = Set<String>()

    private let detector = CardDetector()
    private var frameSkipCounter = 0

    // Audio players for custom sounds
    @State private var detectedCardPlayer: AVAudioPlayer?
    @State private var pointsCardPlayer: AVAudioPlayer?

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
        // Frame skipping for performance (detect every 2 frames)
        guard game.isReady else { return }

        detector.detect(image: pixelBuffer) { newDetections in
            DispatchQueue.main.async {
                self.detections = newDetections

                // Process the best detection
                if let bestDetection = newDetections.first {
                    let cardClass = bestDetection.className

                    if !validatedCards.contains(cardClass) {
                        validatedCards.insert(cardClass)
                        let points = game.addCard(cardClass)

                        // Play sound feedback
                        if points > 0 {
                            playCardSound()
                        } else {
                            playPointsSound()
                        }
                    }
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
        // Load detected_card.wav (0 points)
        if let detectedPath = Bundle.main.path(forResource: "detected_card", ofType: "wav") {
            let detectedURL = URL(fileURLWithPath: detectedPath)
            do {
                detectedCardPlayer = try AVAudioPlayer(contentsOf: detectedURL)
                detectedCardPlayer?.prepareToPlay()
                print("✅ Loaded detected_card.wav")
            } catch {
                print("❌ Failed to load detected_card.wav: \(error)")
            }
        }

        // Load points_card.wav (with points)
        if let pointsPath = Bundle.main.path(forResource: "points_card", ofType: "wav") {
            let pointsURL = URL(fileURLWithPath: pointsPath)
            do {
                pointsCardPlayer = try AVAudioPlayer(contentsOf: pointsURL)
                pointsCardPlayer?.prepareToPlay()
                print("✅ Loaded points_card.wav")
            } catch {
                print("❌ Failed to load points_card.wav: \(error)")
            }
        }
    }

    private func playCardSound() {
        // Play custom sound for card with points
        pointsCardPlayer?.currentTime = 0
        pointsCardPlayer?.play()
    }

    private func playPointsSound() {
        // Play custom sound for card without points
        detectedCardPlayer?.currentTime = 0
        detectedCardPlayer?.play()
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
