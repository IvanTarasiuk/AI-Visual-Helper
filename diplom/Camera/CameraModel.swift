import AVFoundation
import Vision
import CoreML
import SwiftUI
import UIKit
import os.signpost

struct BenchmarkMetrics {
    var modelName: String = ""
    var modelLoadTimeMs: Double?
    var inferenceCount: Int = 0
    var averageLatencyMs: Double = 0
    var minLatencyMs: Double = 0
    var maxLatencyMs: Double = 0
    var averageFPS: Double = 0
}

final class CameraModel: NSObject, ObservableObject {

    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let videoQueue = DispatchQueue(label: "camera.queue")

    private var videoDevice: AVCaptureDevice?

    // MARK: - Published

    @Published var recognizedObject: String = "–"
    @Published var recognizedIdentifier: String = ""
    @Published var confidence: Double = 0.0
    @Published var isDangerous: Bool = false
    @Published private(set) var benchmarkMetrics = BenchmarkMetrics()

    // MARK: - Settings

    @AppStorage("confidenceThreshold") var confidenceThreshold: Double = 0.7
    @AppStorage("modelRefreshRate") var refreshRate: Double = 1.0

    private var lastUpdateTime = Date(timeIntervalSince1970: 0)
    private var visionRequest: VNCoreMLRequest?
    private var currentModelType: ModelType?
    private var isBenchmarkMode = false
    private var totalInferenceTimeMs = 0.0
    private var benchmarkStartTime: CFTimeInterval?
    private let signpostLog = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "diplom",
                                    category: "pointsOfInterest")

    // MARK: - Danger list

    private let dangerObjects: Set<String> = [
        "knife",
        "car",
        "fire",
        "scissors",
        "truck"
    ]

    // MARK: - Session setup

    func configureSession() {
        guard session.inputs.isEmpty else { return }

        session.beginConfiguration()
        session.sessionPreset = .high

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                 for: .video,
                                                 position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            print("❌ Камера недоступна")
            return
        }

        videoDevice = device
        session.addInput(input)

        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        session.commitConfiguration()
    }

    func startSession() {
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }

    func stopSession() {
        guard session.isRunning else { return }
        session.stopRunning()
    }

    func configureBenchmarkMode(_ enabled: Bool) {
        isBenchmarkMode = enabled
    }

    // MARK: - Model setup

    func setModel(_ type: ModelType) {
        if currentModelType != type {
            resetBenchmarkMetrics(for: type)
        }

        guard currentModelType != type || visionRequest == nil else { return }

        currentModelType = type

        let loadSignpostID = OSSignpostID(log: signpostLog)
        let loadStart = CACurrentMediaTime()
        os_signpost(.begin,
                    log: signpostLog,
                    name: "Model Load",
                    signpostID: loadSignpostID,
                    "%{public}s",
                    type.displayName)

        do {
            let mlModel: MLModel

            switch type {
            case .custom:
                mlModel = try MyModel(configuration: .init()).model
            case .mobileNet:
                mlModel = try MobileNetV2(configuration: .init()).model
            case .resNet:
                mlModel = try Resnet50(configuration: .init()).model
            }

            let visionModel = try VNCoreMLModel(for: mlModel)

            visionRequest = VNCoreMLRequest(model: visionModel) { [weak self] request, _ in
                guard
                    let results = request.results as? [VNClassificationObservation],
                    let best = results.first
                else { return }

                DispatchQueue.main.async {
                    guard let self = self else { return }

                    self.confidence = Double(best.confidence)

                    // ВСЕГДА обновляем текст
                    self.recognizedIdentifier = best.identifier
                    self.recognizedObject =
                        "\(best.identifier) (\(Int(best.confidence * 100))%)"

                    // Threshold влияет только на опасность
                    if best.confidence >= Float(self.confidenceThreshold) {
                        self.isDangerous =
                            self.dangerObjects.contains(best.identifier.lowercased())
                    } else {
                        self.isDangerous = false
                    }
                }
            }

            visionRequest?.imageCropAndScaleOption = .centerCrop
            updateModelLoadMetric(startTime: loadStart)

        } catch {
            print("❌ Ошибка загрузки модели:", error)
        }

        os_signpost(.end, log: signpostLog, name: "Model Load", signpostID: loadSignpostID)
    }

    func unloadModel() {
        visionRequest = nil
        currentModelType = nil
    }

    private func resetBenchmarkMetrics(for type: ModelType) {
        totalInferenceTimeMs = 0
        benchmarkStartTime = nil
        benchmarkMetrics = BenchmarkMetrics(modelName: type.displayName)
    }

    private func updateModelLoadMetric(startTime: CFTimeInterval) {
        let durationMs = (CACurrentMediaTime() - startTime) * 1000
        DispatchQueue.main.async {
            self.benchmarkMetrics.modelLoadTimeMs = durationMs
        }
    }

    private func recordInference(durationMs: Double, completedAt timestamp: CFTimeInterval) {
        DispatchQueue.main.async {
            if self.benchmarkStartTime == nil {
                self.benchmarkStartTime = timestamp
            }

            self.totalInferenceTimeMs += durationMs
            self.benchmarkMetrics.inferenceCount += 1

            let count = Double(self.benchmarkMetrics.inferenceCount)
            self.benchmarkMetrics.averageLatencyMs = self.totalInferenceTimeMs / count
            self.benchmarkMetrics.minLatencyMs =
                self.benchmarkMetrics.inferenceCount == 1
                ? durationMs
                : min(self.benchmarkMetrics.minLatencyMs, durationMs)
            self.benchmarkMetrics.maxLatencyMs =
                max(self.benchmarkMetrics.maxLatencyMs, durationMs)

            if self.benchmarkMetrics.inferenceCount > 1,
               let benchmarkStartTime = self.benchmarkStartTime {
                let elapsed = timestamp - benchmarkStartTime
                if elapsed > 0 {
                    self.benchmarkMetrics.averageFPS = count / elapsed
                }
            }
        }
    }

    // MARK: - Zoom

    func zoom(factor: CGFloat) {
        guard let device = videoDevice else { return }

        do {
            try device.lockForConfiguration()

            let maxZoom = min(device.activeFormat.videoMaxZoomFactor, 10.0)
            let newScale = max(1.0, min(factor, maxZoom))

            device.videoZoomFactor = newScale
            device.unlockForConfiguration()
        } catch {
            print("Ошибка изменения зума: \(error)")
        }
    }
}

extension CameraModel: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {

        let now = Date()
        if !isBenchmarkMode, refreshRate > 0 {
            guard now.timeIntervalSince(lastUpdateTime) > (1.0 / refreshRate) else { return }
        }
        lastUpdateTime = now

        guard
            let buffer = CMSampleBufferGetImageBuffer(sampleBuffer),
            let request = visionRequest
        else { return }

        let inferenceSignpostID = OSSignpostID(log: signpostLog)
        let inferenceStart = CACurrentMediaTime()
        os_signpost(.begin,
                    log: signpostLog,
                    name: "Inference",
                    signpostID: inferenceSignpostID,
                    "%{public}s",
                    currentModelType?.displayName ?? "Unknown")

        let handler = VNImageRequestHandler(cvPixelBuffer: buffer,
                                            orientation: .right,
                                            options: [:])

        try? handler.perform([request])
        os_signpost(.end,
                    log: signpostLog,
                    name: "Inference",
                    signpostID: inferenceSignpostID)

        if isBenchmarkMode {
            let completedAt = CACurrentMediaTime()
            recordInference(durationMs: (completedAt - inferenceStart) * 1000,
                            completedAt: completedAt)
        }
    }
}
