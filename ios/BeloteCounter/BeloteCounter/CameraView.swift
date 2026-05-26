import SwiftUI
import AVFoundation

struct CameraView: UIViewRepresentable {
    @Binding var detections: [Detection]
    let onFrame: (CVPixelBuffer) -> Void

    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.onFrame = onFrame
        return view
    }

    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        uiView.detections = detections
    }
}

class CameraPreviewView: UIView {
    var onFrame: ((CVPixelBuffer) -> Void)?
    var detections: [Detection] = [] {
        didSet {
            setNeedsDisplay()
        }
    }

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let videoOutput = AVCaptureVideoDataOutput()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCamera()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCamera()
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else { return }

        captureSession.sessionPreset = .high

        // Get back camera
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("❌ No camera available")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)

            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }

            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]

            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }

            // Setup preview layer
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.videoGravity = .resizeAspectFill
            previewLayer?.frame = bounds
            if let previewLayer = previewLayer {
                layer.addSublayer(previewLayer)
            }

            // Start session
            DispatchQueue.global(qos: .userInitiated).async {
                captureSession.startRunning()
            }
        } catch {
            print("❌ Camera setup error: \(error)")
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext() else { return }

        // Draw bounding boxes
        context.setStrokeColor(UIColor.green.cgColor)
        context.setLineWidth(2.0)

        for detection in detections {
            // Convert normalized coordinates to view coordinates
            let box = convertBoundingBox(detection.boundingBox)
            context.stroke(box)
        }
    }

    private func convertBoundingBox(_ box: CGRect) -> CGRect {
        // Vision coordinates are normalized and origin at bottom-left
        // UIKit coordinates have origin at top-left
        let width = bounds.width
        let height = bounds.height

        let x = box.origin.x * width
        let y = (1 - box.origin.y - box.height) * height
        let w = box.width * width
        let h = box.height * height

        return CGRect(x: x, y: y, width: w, height: h)
    }
}

extension CameraPreviewView: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        onFrame?(pixelBuffer)
    }
}
