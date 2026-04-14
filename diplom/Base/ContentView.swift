//
//  ContentView.swift
//  diplom
//
//  Created by Иван Тарасюк on 20.12.2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            BenchmarkView()
                .tabItem {
                    Label("Исследование", systemImage: "chart.xyaxis.line")
                }

            SettingsView()
                .tabItem {
                    Label("Настройки", systemImage: "gear")
                }
        }
    }
}

struct BenchmarkView: View {
    @State private var selectedModel: ModelType = .custom
    @State private var runID = UUID()

    var body: some View {
        CameraView(modelType: selectedModel,
                   isActive: true,
                   benchmarkMode: true)
            .id(runID)
            .safeAreaInset(edge: .top) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Сравнительное исследование моделей")
                        .font(.headline)

                    Picker("Модель", selection: $selectedModel) {
                        ForEach(ModelType.allCases) { model in
                            Text(model.displayName).tag(model)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedModel) { _ in
                        runID = UUID()
                    }

                    Button("Новый прогон") {
                        runID = UUID()
                    }
                    .buttonStyle(.borderedProminent)

                    Text("Для чистого эксперимента новый прогон пересоздаёт камеру и заново загружает модель.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial)
            }
    }
}
