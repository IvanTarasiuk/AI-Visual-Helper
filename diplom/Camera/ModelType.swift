//
//  ModelType.swift
//  diplom
//
//  Created by Иван Тарасюк on 20.12.2025.
//

enum ModelType {
    case custom
    case mobileNet
    case resNet

    var displayName: String {
        switch self {
        case .custom: return "Моя модель"
        case .mobileNet: return "MobileNetV2"
        case .resNet: return "ResNet-50"
        }
    }
}
