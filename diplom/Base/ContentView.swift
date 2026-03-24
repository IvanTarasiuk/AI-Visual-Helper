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
            CameraView(modelType: .custom)
                .tabItem {
                    Label("Моя", systemImage: "1.circle")
                }

            CameraView(modelType: .mobileNet)
                .tabItem {
                    Label("MobileNetV2", systemImage: "2.circle")
                }

            CameraView(modelType: .resNet)
                .tabItem {
                    Label("ResNet50", systemImage: "3.circle")
                }

            SettingsView()
                .tabItem {
                    Label("Настройки", systemImage: "gear")
                }
        }
    }
}
