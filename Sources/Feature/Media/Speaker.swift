//
//  Speaker.swift
//  Ext
//
//  Created by guojian on 2023/2/17.
//

import Foundation
import AVFoundation

/// 文本说话 UI 协议
public protocol SpeakerUIType: UIView {
    var isSpeaking: Bool { get set }
}

/// 文本说话(文本转语音并播放)
public final class Speaker {
    public static let shared = Speaker()
    private init() {
        Ext.log("rate: \([AVSpeechUtteranceMinimumSpeechRate, AVSpeechUtteranceDefaultSpeechRate, AVSpeechUtteranceMaximumSpeechRate])")
        Ext.log("voices: \(AVSpeechSynthesisVoice.currentLanguageCode()) - \(AVSpeechSynthesisVoice.speechVoices().map({ $0.log }))")
        Ext.log("voiceMap: \(voiceMap.mapValues({ $0.map({ $0.log }) }))")
        Ext.log("enabled languages: \(enabledLanguages)")
    }
    
    /// 说话口音表 (eg: [en-US: [voice1, voice2]])
    private lazy var voiceMap: [String: [AVSpeechSynthesisVoice]] = {
        var map = [String: [AVSpeechSynthesisVoice]]()
        for voice in AVSpeechSynthesisVoice.speechVoices() {
            var voices = map[voice.language] ?? [AVSpeechSynthesisVoice]()
            voices.append(voice)
            map[voice.language] = voices
        }
        return map
    }()
    /// 可用的语言 (eg：[en-US、zh-CN])
    private lazy var enabledLanguages: [String] = voiceMap.map { $0.key }
    
    /// 文本语音合成器
    private lazy var synthesizer = ExtSynthesizer()
    /// 当前 speaker 对应的 UI
    private weak var speakerUI: SpeakerUIType?
}

public extension Speaker {
    /// 语言是否可用
    /// - Parameter language: 语言 (eg: zh-CN、en-US)
    func isEnabled(language: String) -> Bool {
        enabledLanguages.contains(language)
    }
    
    /// 根据语言码获取最优语言
    /// - Parameter languageCode: 语言码 (eg: zh、en)
    func language(languageCode: String) -> String? {
        Ext.log("preferredLanguages: \(Locale.preferredLanguages)")
        if let language = Locale.preferredLanguages.first(where: { $0.hasPrefix(languageCode) }),
           isEnabled(language: language) {
            Ext.log("use pref langugae: \(language)")
            return language
        }
        if let countryCode = Locale.current.regionCode {
            let language = "\(languageCode)-\(countryCode)"
            if isEnabled(language: language) {
                Ext.log("use current country : \(language)")
                return language
            }
        }
        return enabledLanguages.first(where: { $0.hasPrefix(languageCode) })
    }
}
public extension Speaker {
    /// 说文本
    /// - Parameters:
    ///   - text: 文本内容
    ///   - languageCode: 说话语言码 (eg: zh、en)
    ///   - speakerUI: 绑定的 UI
    func speak(text: String, languageCode: String, speakerUI: SpeakerUIType? = nil) {
        guard let language = language(languageCode: languageCode) else {
            Ext.log("speak language code: \(languageCode) not available.", tag: .error)
            return
        }
        speak(text: text, language: language, speakerUI: speakerUI)
    }
    
    /// 说文本
    /// - Parameters:
    ///   - text: 文本内容
    ///   - language: 说话语言 (eg: zh-CN、en-US)
    ///   - speakerUI: 绑定的 UI
    func speak(text: String, language: String, speakerUI: SpeakerUIType? = nil) {
        if synthesizer.isSpeaking {
            Ext.log("正在说话")
            synthesizer.stop()
            Ext.log("立即停止")
            self.speakerUI?.isSpeaking = false
            self.speakerUI = nil
        }
        Ext.log("speak: \(language) - \(text)")
        guard isEnabled(language: language) else {
            Ext.log("speak language \(language) not available.", tag: .error)
            return
        }
        self.speakerUI = speakerUI
        
        synthesizer.speak(text: text, language: language) { [weak self] action in
            guard let self else { return }
            switch action {
            case .start:
                self.speakerUI?.isSpeaking = true
            default:
                self.speakerUI?.isSpeaking = false
            }
        }
    }
    
    /// 停止说文本
    func stop() {
        synthesizer.stop()
    }
}

// MARK: - Syntheizer

private class ExtSynthesizer: NSObject {
    enum Action {
        case start
        case finish
        case pause
        case `continue`
        case cancel
    }
    
    var logEnabled: Bool = false
    
    private lazy var avSynthesizer: AVSpeechSynthesizer =  {
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.delegate = self
        return synthesizer
    }()
    private var handler: Ext.DataHandler<ExtSynthesizer.Action>?
    
    var isSpeaking: Bool { avSynthesizer.isSpeaking }
    
    /// 开始说文本
    /// - Parameters:
    ///   - text: 文本内容
    ///   - language: 文本语言 (eg: en-US、zh-CN)
    func speak(text: String, language: String, handler: Ext.DataHandler<ExtSynthesizer.Action>?) {
        if avSynthesizer.isSpeaking {
            avSynthesizer.stopSpeaking(at: .immediate)
            self.handler?(.finish)
            self.handler = nil
        }
        self.handler = handler
        Ext.log("speak: \(language) - \(text)")
        let utterance = AVSpeechUtterance(string: text)
        let voice = AVSpeechSynthesisVoice(language: language)
        utterance.voice = voice
        avSynthesizer.speak(utterance)
    }
    /// 停止
    func stop() {
        guard avSynthesizer.isSpeaking else { return }
        avSynthesizer.stopSpeaking(at: .immediate)
    }
    /// 暂停
    func pause() {
        guard avSynthesizer.isSpeaking else { return }
        avSynthesizer.pauseSpeaking(at: .immediate)
    }
    /// 继续
    func `continue`() {
        guard avSynthesizer.isPaused else { return }
        avSynthesizer.continueSpeaking()
    }
}
extension ExtSynthesizer: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Ext.log("start - \(utterance.log)", logEnabled: logEnabled)
        handler?(.start)
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Ext.log("finish - \(utterance.log)", logEnabled: logEnabled)
        handler?(.finish)
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        Ext.log("pause - \(utterance.log)", logEnabled: logEnabled)
        handler?(.pause)
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        Ext.log("continue - \(utterance.log)", logEnabled: logEnabled)
        handler?(.continue)
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Ext.log("cancel - \(utterance.log)", logEnabled: logEnabled)
        handler?(.cancel)
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        //Ext.log("\(characterRange) - \(utterance.log)", logEnabled: logEnabled)
    }
}

// MARK: - Log

extension AVSpeechSynthesisVoice: DataLogable {
    public var log: String {
        "{\"identifier\": \(identifier), \"language\": \(language), \"name\": \(name)}"
    }
}
extension AVSpeechUtterance: DataLogable {
    public var log: String { "\(speechString)" }
}
