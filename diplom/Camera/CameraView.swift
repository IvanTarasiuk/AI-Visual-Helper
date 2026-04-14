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
                    cameraModel.configureSession()
                    cameraModel.setModel(modelType)
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
        .onChange(of: cameraModel.recognizedIdentifier) { newIdentifier in
            guard isActive else { return }

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
            cameraModel.setModel(modelType)
            cameraModel.startSession()
            return
        }

        cameraModel.stopSession()
        speechManager.stop()
        speakWorkItem?.cancel()
        hapticManager.stopDangerPattern()
    }
}
