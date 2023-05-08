//
//  AudioSpeaker.swift
//  Ext
//
//  Created by guojian on 2023/4/13.
//

import Foundation
import AVFoundation
import UIKit

/// 音频播放器 UI 协议 (播放音频资源时，用于调整播放相关 UI 的状态)
public protocol AudioSpeakerUIType: UIView {
    /// 资源缓存中
    var isBuffering: Bool { get set }
    /// 正在播放中
    var isSpeaking: Bool { get set }
    
    /// 播放到指定时间点
    func speakTo(time: TimeInterval, duration: TimeInterval)
}
public extension AudioSpeakerUIType {
    func speakTo(time: TimeInterval, duration: TimeInterval) {}
}

/// 音频播放管理器
public final class AudioSpeaker: ExtInnerLogable {
    public var logLevel: Ext.LogLevel = .debug {
        didSet { player.logLevel = logLevel }
    }
    
    public static let shared = AudioSpeaker()
    private init() {}
    deinit {
        player.clear()
    }
    
    private lazy var player: ExtPlayer = {
        let player = ExtPlayer()
        player.delegate = self
        player.logLevel = logLevel
        return player
    }()
    
    
    /// 播放关联 UI
    private weak var speakerUI: AudioSpeakerUIType?
    /// 播放资源 item
    private var playerItem: AVPlayerItem? {
        didSet {
            ext.log("\(oldValue) -> \(playerItem)")
            guard let item = playerItem else {
                player.clearData()
                return
            }
            player.periodicTime = 0.1
            player.playerItem = item
        }
    }
}
extension AudioSpeaker: ExtPlayerDelegate {
    
    public func extPlayer(_ player: ExtPlayer, status: ExtPlayer.Status) {
        ext.log("\(player)")
        
        switch status {
        case .paused:
            ext.log("player paused.")
            speakerUI?.speakTo(time: player.currentTime, duration: player.duration ?? 0)
            speakerUI?.isBuffering = false
            speakerUI?.isSpeaking = false
        case .playToEnd:
            ext.log("player to end.")
            speakerUI?.speakTo(time: 0, duration: player.duration ?? 0)
            speakerUI?.isSpeaking = false
        case .failed(let error):
            ext.log("play error", error: error)
            speakerUI?.isBuffering = false
            speakerUI?.isSpeaking = false
        default: ()
        }
    }
    public func extPlayer(_ player: ExtPlayer, bufferStatus status: ExtPlayer.BufferStatus) {
        ext.log("isBuffering: \(player.isBuffering))")
        speakerUI?.isBuffering = player.isBuffering
    }
    public func extPlayer(_ player: ExtPlayer, timeStatus status: ExtPlayer.TimeStatus) {
        switch status {
        case .periodic(let time, let duration):
            //ext.log("playing: \(time) / \(duration)")
            speakerUI?.speakTo(time: time, duration: duration)
        default: ()
        }
    }
}

// MARK: - Public

public extension AudioSpeaker {
    
    /// 播放音频资源
    /// - Parameters:
    ///   - url: 资源 URL
    ///   - time: 播放时间点
    ///   - speakerUI: 音频播放关联的 UI
    func speak(url: URL, time: TimeInterval? = nil, speakerUI: AudioSpeakerUIType?) {
        speak(playerItem: AVPlayerItem(url: url), time: time, speakerUI: speakerUI)
    }
    
    /// 播放音频资源
    /// - Parameters:
    ///   - playerItem: 播放资源 item
    ///   - time: 播放时间点
    ///   - speakerUI: 音频播放关联的 UI
    func speak(playerItem: AVPlayerItem, time: TimeInterval? = nil, speakerUI: AudioSpeakerUIType?) {
        if player.isPlaying { self.pause() }
        
        ext.log("play \(playerItem) - \(time) | \(player) | \(speakerUI?.description ?? "")")
        
        self.playerItem = playerItem
        self.speakerUI = speakerUI
        
        guard let time = time, time > 0 else {
            player.play()
            speakerUI?.isSpeaking = true
            return
        }
        player.seek(time) { [weak self] _ in
            guard let self else { return }
            self.player.play()
            self.speakerUI?.isSpeaking = true
        }
    }
    
    /// 暂停播放
    func pause() {
        ext.log("pause \(player.currentTime) | \(player) | \(playerItem)")
        player.pause()
    }
    
    /// 停止当前播放
    func stop() {
        self.pause()
        
        speakerUI = nil
        playerItem = nil
    }
}
