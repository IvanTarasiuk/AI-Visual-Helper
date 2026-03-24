//
//  HapticManager.swift
//  diplom
//
//  Created by Иван Тарасюк on 24.02.2026.
//

import UIKit
import SwiftUI

final class HapticManager: ObservableObject {

    @AppStorage("isHapticsOn") var isHapticsOn: Bool = true

    private var dangerTimer: Timer?

    func singlePulse() {
        guard isHapticsOn else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    func startDangerPattern() {
        guard isHapticsOn else { return }

        stopDangerPattern()

        dangerTimer = Timer.scheduledTimer(withTimeInterval: 1.2,
                                           repeats: true) { _ in
            self.tripleFastPulse()
        }
    }

    func stopDangerPattern() {
        dangerTimer?.invalidate()
        dangerTimer = nil
    }

    private func tripleFastPulse() {
        guard isHapticsOn else { return }

        let generator = UIImpactFeedbackGenerator(style: .heavy)

        generator.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            generator.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            generator.impactOccurred()
        }
    }
}
