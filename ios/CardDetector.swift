import CoreML
import Vision
import UIKit

struct Detection {
    let className: String
    let confidence: Float
    let boundingBox: CGRect
}

class CardDetector {
    private var model: VNCoreMLModel?

    private let classNames = [
        "10C", "10D", "10H", "10S", "2C", "2D", "2H", "2S",
        "3C", "3D", "3H", "3S", "4C", "4D", "4H", "4S",
        "5C", "5D", "5H", "5S", "6C", "6D", "6H", "6S",
        "7C", "7D", "7H", "7S", "8C", "8D", "8H", "8S",
        "9C", "9D", "9H", "9S", "AC", "AD", "AH", "AS",
        "JC", "JD", "JH", "JS", "KC", "KD", "KH", "KS",
        "QC", "QD", "QH", "QS"
    ]

    init() {
        loadModel()
    }

    private func loadModel() {
        do {
            // Load the Core ML model
            // Note: Replace "PlayingCardsModel" with your actual model name
            let config = MLModelConfiguration()
            config.computeUnits = .all  // Use Neural Engine when available

            // The model will be automatically compiled by Xcode
            // You need to add PlayingCardsModel.mlpackage to your Xcode project
            guard let modelURL = Bundle.main.url(forResource: "PlayingCardsModel", withExtension: "mlmodelc") else {
                print("❌ Model file not found")
                return
            }

            let mlModel = try MLModel(contentsOf: modelURL, configuration: config)
            model = try VNCoreMLModel(for: mlModel)
            print("✅ Core ML model loaded successfully")
        } catch {
            print("❌ Failed to load Core ML model: \(error)")
        }
    }

    func detect(image: CVPixelBuffer, completion: @escaping ([Detection]) -> Void) {
        guard let model = model else {
            completion([])
            return
        }

        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ Detection error: \(error)")
                completion([])
                return
            }

            guard let results = request.results as? [VNRecognizedObjectObservation] else {
                completion([])
                return
            }

            let detections = results.compactMap { observation -> Detection? in
                guard let label = observation.labels.first,
                      label.confidence > 0.3 else { return nil }

                return Detection(
                    className: label.identifier,
                    confidence: label.confidence,
                    boundingBox: observation.boundingBox
                )
            }

            // Merge nearby detections of the same class
            let merged = self.mergeNearbyDetections(detections)
            completion(merged)
        }

        request.imageCropAndScaleOption = .scaleFill

        let handler = VNImageRequestHandler(cvPixelBuffer: image, options: [:])

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("❌ Failed to perform detection: \(error)")
                completion([])
            }
        }
    }

    private func mergeNearbyDetections(_ detections: [Detection]) -> [Detection] {
        guard !detections.isEmpty else { return [] }

        var merged: [Detection] = []
        var used = Set<Int>()

        for i in 0..<detections.count {
            if used.contains(i) { continue }

            let det1 = detections[i]
            var bestDet = det1
            used.insert(i)

            for j in (i+1)..<detections.count {
                if used.contains(j) { continue }

                let det2 = detections[j]

                // Check if same class and close proximity
                if det1.className == det2.className {
                    let center1 = CGPoint(
                        x: det1.boundingBox.midX,
                        y: det1.boundingBox.midY
                    )
                    let center2 = CGPoint(
                        x: det2.boundingBox.midX,
                        y: det2.boundingBox.midY
                    )

                    let distance = hypot(center1.x - center2.x, center1.y - center2.y)

                    // Merge if distance < 0.3 (normalized coordinates)
                    if distance < 0.3 {
                        used.insert(j)
                        // Keep the one with higher confidence
                        if det2.confidence > bestDet.confidence {
                            bestDet = det2
                        }
                    }
                }
            }

            merged.append(bestDet)
        }

        return merged.sorted { $0.confidence > $1.confidence }
    }
}
