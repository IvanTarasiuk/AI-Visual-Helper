//
//  SettingsView.swift
//  diplom
//
//  Created by Иван Тарасюк on 20.12.2025.
//

import SwiftUI

struct SettingsView: View {

    @AppStorage("confidenceThreshold") var confidenceThreshold: Double = 0.7
    @AppStorage("isVoiceOn") var isVoiceOn = true
    @AppStorage("isHapticsOn") var isHapticsOn = true
    @AppStorage("isDarkMode") var isDarkMode = false

    var body: some View {
        Form {
            Section(header: Text("Распознавание")) {
                Slider(value: $confidenceThreshold,
                       in: 0.5...0.95,
                       step: 0.05)

                Text("Порог уверенности: \(Int(confidenceThreshold * 100))%")
            }

            Section(header: Text("Обратная связь")) {
                Toggle("Голос", isOn: $isVoiceOn)
                Toggle("Вибрация", isOn: $isHapticsOn)
            }

            Section {
                Toggle("Тёмная тема", isOn: $isDarkMode)
            }
        }
        .navigationTitle("Настройки")
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}
