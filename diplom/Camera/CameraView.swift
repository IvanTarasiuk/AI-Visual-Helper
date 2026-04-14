//
//  CameraView.swift
//  diplom
//
//  Created by Иван Тарасюк on 20.12.2025.
//

import SwiftUI
import AVFoundation
import UIKit

struct CameraView: View {

    let modelType: ModelType
    let isActive: Bool
    var benchmarkMode: Bool = false

    @StateObject private var cameraModel = CameraModel()
    @StateObject private var speechManager = SpeechManager()
    @StateObject private var hapticManager = HapticManager()

    @State private var lastSpokenIdentifier: String = ""
    @State private var speakWorkItem: DispatchWorkItem?
    @State private var currentZoomFactor: CGFloat = 1.0

    var body: some View {
        ZStack {
            CameraPreview(cameraModel: cameraModel)
                .onAppear {
                    cameraModel.configureBenchmarkMode(benchmarkMode)
                    updateActivityState(isActive)
                }
                .onDisappear {
                    updateActivityState(false)
                }
                .edgesIgnoringSafeArea(.all)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let newZoom = currentZoomFactor * value
                            cameraModel.zoom(factor: newZoom)
                        }
                        .onEnded { value in
                            currentZoomFactor *= value
                        }
                )

            VStack {
                if benchmarkMode {
                    benchmarkOverlay
                        .padding(.top, 12)
                }

                Spacer()

                Text(cameraModel.recognizedObject)
                    .font(.title)
                    .bold()
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.yellow)
                    .cornerRadius(16)
                    .padding(.bottom, 30)
            }
        }
        .onChange(of: isActive) { active in
            updateActivityState(active)
        }
        .onChange(of: benchmarkMode) { enabled in
            cameraModel.configureBenchmarkMode(enabled)
        }
        .onChange(of: cameraModel.recognizedIdentifier) { newIdentifier in
            guard isActive else { return }
            guard !benchmarkMode else { return }

            speechManager.stop()
            speakWorkItem?.cancel()

            // Вибрация при изменении объекта
            if newIdentifier != lastSpokenIdentifier {
                hapticManager.singlePulse()
            }

            // Опасный объект
            if cameraModel.isDangerous {
                hapticManager.startDangerPattern()
            } else {
                hapticManager.stopDangerPattern()
            }

            let workItem = DispatchWorkItem {
                if newIdentifier != lastSpokenIdentifier {
                    speechManager.speak(newIdentifier)
                    lastSpokenIdentifier = newIdentifier
                }
            }

            speakWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0,
                                          execute: workItem)
        }
    }

    private func updateActivityState(_ isActive: Bool) {
        if isActive {
            cameraModel.configureSession()
            cameraModel.configureBenchmarkMode(benchmarkMode)
            cameraModel.setModel(modelType)
            cameraModel.startSession()
            return
        }

        cameraModel.stopSession()
        cameraModel.unloadModel()
        speechManager.stop()
        speakWorkItem?.cancel()
        hapticManager.stopDangerPattern()
    }

    private var benchmarkOverlay: some View {
        let metrics = cameraModel.benchmarkMetrics

        return VStack(alignment: .leading, spacing: 8) {
            Text(metrics.modelName.isEmpty ? modelType.displayName : metrics.modelName)
                .font(.headline)

            Text("Загрузка модели: \(formatted(metrics.modelLoadTimeMs))")
            Text("Средняя задержка: \(formatted(metrics.averageLatencyMs, suffix: "мс"))")
            Text("Min / Max: \(formatted(metrics.minLatencyMs, suffix: "мс")) / \(formatted(metrics.maxLatencyMs, suffix: "мс"))")
            Text("FPS: \(metrics.averageFPS, specifier: "%.2f")")
            Text("Инференсов: \(metrics.inferenceCount)")
        }
        .font(.caption.monospacedDigit())
        .foregroundColor(.white)
        .padding(12)
        .background(Color.black.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private func formatted(_ value: Double?, suffix: String = "мс") -> String {
        guard let value else { return "—" }
        return String(format: "%.2f %@", value, suffix)
    }

    private func formatted(_ value: Double, suffix: String = "мс") -> String {
        guard value > 0 else { return "—" }
        return String(format: "%.2f %@", value, suffix)
    }
}
