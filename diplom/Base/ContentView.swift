//
//  ContentView.swift
//  diplom
//
//  Created by Иван Тарасюк on 20.12.2025.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            CameraView(modelType: .custom, isActive: selectedTab == 0)
                .tag(0)
                .tabItem {
                    Label("Моя", systemImage: "1.circle")
                }

            CameraView(modelType: .mobileNet, isActive: selectedTab == 1)
                .tag(1)
                .tabItem {
                    Label("MobileNetV2", systemImage: "2.circle")
                }

            CameraView(modelType: .resNet, isActive: selectedTab == 2)
                .tag(2)
                .tabItem {
                    Label("ResNet50", systemImage: "3.circle")
                }

            SettingsView()
                .tag(3)
                .tabItem {
                    Label("Настройки", systemImage: "gear")
                }
        }
    }
}
