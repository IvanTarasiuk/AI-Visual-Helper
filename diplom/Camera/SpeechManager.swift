//
//  SpeechManager.swift
//  diplom
//
//  Created by Иван Тарасюк on 24.02.2026.
//

import AVFoundation
import SwiftUI

final class SpeechManager: ObservableObject {
    
    private let synthesizer = AVSpeechSynthesizer()
    
    @AppStorage("isVoiceOn") var isVoiceOn: Bool = true
    
    func speak(_ text: String) {
        guard isVoiceOn else { return }
        
        stop() // чтобы не было наложения
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ru-RU")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        
        synthesizer.speak(utterance)
    }
    
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}
