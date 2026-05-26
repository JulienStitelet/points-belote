// Card detector using ONNX Runtime Web
class CardDetector {
    constructor() {
        this.session = null;
        this.classNames = [
            '10C', '10D', '10H', '10S', '2C', '2D', '2H', '2S',
            '3C', '3D', '3H', '3S', '4C', '4D', '4H', '4S',
            '5C', '5D', '5H', '5S', '6C', '6D', '6H', '6S',
            '7C', '7D', '7H', '7S', '8C', '8D', '8H', '8S',
            '9C', '9D', '9H', '9S', 'AC', 'AD', 'AH', 'AS',
            'JC', 'JD', 'JH', 'JS', 'KC', 'KD', 'KH', 'KS',
            'QC', 'QD', 'QH', 'QS'
        ];
    }

    async init() {
        try {
            // Load ONNX model
            this.session = await ort.InferenceSession.create('model.onnx');
            console.log('YOLO model loaded');
        } catch (err) {
            console.error('Failed to load model:', err);
            alert('Modèle non chargé. Placez model.onnx dans iphone/');
        }
    }

    async detect(videoElement) {
        if (!this.session) return [];

        try {
            // Prepare input tensor from video (reduced resolution for performance)
            const inputSize = 416;  // Reduced from 640 to 416 for faster inference
            const canvas = document.createElement('canvas');
            canvas.width = inputSize;
            canvas.height = inputSize;
            const ctx = canvas.getContext('2d');

            // Draw video frame to canvas (letterbox to inputSize x inputSize)
            const scale = Math.min(inputSize / videoElement.videoWidth, inputSize / videoElement.videoHeight);
            const w = videoElement.videoWidth * scale;
            const h = videoElement.videoHeight * scale;
            const x = (inputSize - w) / 2;
            const y = (inputSize - h) / 2;

            ctx.fillStyle = '#000';
            ctx.fillRect(0, 0, inputSize, inputSize);
            ctx.drawImage(videoElement, x, y, w, h);

            // Get image data and normalize
            const imageData = ctx.getImageData(0, 0, inputSize, inputSize);
            const data = imageData.data;
            const input = new Float32Array(3 * inputSize * inputSize);

            // Convert RGBA to RGB and normalize [0-255] to [0-1]
            for (let i = 0; i < inputSize * inputSize; i++) {
                input[i] = data[i * 4] / 255.0;                    // R
                input[inputSize * inputSize + i] = data[i * 4 + 1] / 255.0;   // G
                input[inputSize * inputSize * 2 + i] = data[i * 4 + 2] / 255.0; // B
            }

            // Create tensor
            const tensor = new ort.Tensor('float32', input, [1, 3, inputSize, inputSize]);

            // Run inference
            const feeds = {};
            feeds[this.session.inputNames[0]] = tensor;
            const results = await this.session.run(feeds);

            // Parse YOLOv8 output
            const output = results[this.session.outputNames[0]];
            const detections = this.parseYOLOv8Output(output, videoElement, scale, x, y);

            return detections;
        } catch (err) {
            console.error('Detection error:', err);
            return [];
        }
    }

    parseYOLOv8Output(output, videoElement, scale, offsetX, offsetY) {
        const detections = [];
        const data = output.data;
        const dims = output.dims; // [1, 84, 8400] for YOLOv8

        const numClasses = dims[1] - 4; // 80 or 52 classes
        const numBoxes = dims[2];

        for (let i = 0; i < numBoxes; i++) {
            // Get box coordinates (first 4 values)
            const x = data[i];
            const y = data[numBoxes + i];
            const w = data[2 * numBoxes + i];
            const h = data[3 * numBoxes + i];

            // Get class scores (remaining values)
            let maxScore = 0;
            let maxClass = 0;

            for (let c = 0; c < numClasses; c++) {
                const score = data[(4 + c) * numBoxes + i];
                if (score > maxScore) {
                    maxScore = score;
                    maxClass = c;
                }
            }

            // Filter by confidence threshold
            if (maxScore > 0.5) {
                // Convert from model coords to video coords
                const x1 = ((x - w / 2) - offsetX) / scale;
                const y1 = ((y - h / 2) - offsetY) / scale;
                const x2 = ((x + w / 2) - offsetX) / scale;
                const y2 = ((y + h / 2) - offsetY) / scale;

                detections.push({
                    className: this.classNames[maxClass] || 'unknown',
                    confidence: maxScore,
                    bbox: [
                        Math.max(0, x1),
                        Math.max(0, y1),
                        Math.min(videoElement.videoWidth, x2),
                        Math.min(videoElement.videoHeight, y2)
                    ]
                });
            }
        }

        // Merge nearby duplicate detections
        return this.mergeNearbyDetections(detections);
    }

    mergeNearbyDetections(detections, threshold = 200) {
        if (detections.length === 0) return [];

        const merged = [];
        const used = new Set();

        for (let i = 0; i < detections.length; i++) {
            if (used.has(i)) continue;

            const cluster = [detections[i]];
            used.add(i);

            for (let j = i + 1; j < detections.length; j++) {
                if (used.has(j)) continue;

                if (detections[i].className === detections[j].className) {
                    const dist = this.bboxDistance(detections[i].bbox, detections[j].bbox);
                    if (dist < threshold) {
                        cluster.push(detections[j]);
                        used.add(j);
                    }
                }
            }

            merged.push(this.mergeCluster(cluster));
        }

        // Sort by confidence (best first)
        return merged.sort((a, b) => b.confidence - a.confidence);
    }

    bboxDistance(bbox1, bbox2) {
        const cx1 = (bbox1[0] + bbox1[2]) / 2;
        const cy1 = (bbox1[1] + bbox1[3]) / 2;
        const cx2 = (bbox2[0] + bbox2[2]) / 2;
        const cy2 = (bbox2[1] + bbox2[3]) / 2;

        return Math.sqrt((cx1 - cx2) ** 2 + (cy1 - cy2) ** 2);
    }

    mergeCluster(cluster) {
        if (cluster.length === 1) return cluster[0];

        const avgConf = cluster.reduce((sum, d) => sum + d.confidence, 0) / cluster.length;

        const x1 = Math.min(...cluster.map(d => d.bbox[0]));
        const y1 = Math.min(...cluster.map(d => d.bbox[1]));
        const x2 = Math.max(...cluster.map(d => d.bbox[2]));
        const y2 = Math.max(...cluster.map(d => d.bbox[3]));

        return {
            className: cluster[0].className,
            confidence: avgConf,
            bbox: [x1, y1, x2, y2]
        };
    }
}
