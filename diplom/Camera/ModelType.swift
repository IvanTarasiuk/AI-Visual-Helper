//
//  ModelType.swift
//  diplom
//
//  Created by Иван Тарасюк on 20.12.2025.
//

enum ModelType: CaseIterable, Identifiable {
    case custom
    case mobileNet
    case resNet

    var id: Self { self }

    var displayName: String {
        switch self {
        case .custom: return "Моя модель"
        case .mobileNet: return "MobileNetV2"
        case .resNet: return "ResNet-50"
        }
    }
}
