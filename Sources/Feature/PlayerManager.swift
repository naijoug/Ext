//
//  PlayerManager.swift
//  Ext
//
//  Created by najoug on 2020/11/27.
//

import UIKit
import AVFoundation

private var AudioSessionCategoryContext = 0

/// 播放器管理
public final class PlayerManager {
    public static let shared = PlayerManager()
    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(routeChange(_:)), name: AVAudioSession.routeChangeNotification, object: nil)
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// 是否静音🔇
    public var isMuted: Bool = true
}

public extension PlayerManager {
    
    enum AudioCategory {
        /// 播放模式
        case playback
        /// 播放录制模式
        case playAndRecord
    }
    
    /// 设置音频分类
    func setAudio(_ category: AudioCategory) {
        switch category {
        case .playback:         playback()
        case .playAndRecord:    playAndRecord()
        }
    }
    
    /// 打印当前 Audio 设置
    func logAudio(_ message: String = "") {
        let shared = AVAudioSession.sharedInstance()
        Ext.debug("\(message) category: \(shared.category) | options \(shared.categoryOptions)")
    }
}

private extension PlayerManager {
    
    @objc
    func routeChange(_ noti: Notification) {
        let changeReason = noti.userInfo?[AVAudioSessionRouteChangeReasonKey] as? AVAudioSession.RouteChangeReason
        switch changeReason {
        case .oldDeviceUnavailable: // 旧输出设备不可用
            let previousRoute = noti.userInfo?[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription
            if let port = previousRoute?.outputs.first {
                switch port.portType {
                case .headphones:
                    /**
                     拔出耳机时:
                        1> 系统默认会把输出设备设置为扬声器
                        2> 但是 Category 为 playAndRecord 时，则会把输入设备设置为听筒
                     */
                    Ext.debug("之前输入设备是耳机🎧，拔出耳机。")
                    // 强制设为扬声器
//                    do {
//                        try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
//                    } catch {
//                        Ext.debug("force output to speaker failed. \(error.localizedDescription)")
//                    }
                default: break
                }
            }
        default: break
        }
        
        let route = AVAudioSession.sharedInstance().currentRoute
        var isHeadphoneEnabled = false
        for desc in route.outputs {
            Ext.debug("\(desc)")
            if desc.portType == .headphones {
                isHeadphoneEnabled = true
            }
        }
        Ext.debug("isHeadphoneEnabled: \(isHeadphoneEnabled)")
    }
    
    /// 播放和录音
    func playAndRecord() {
        let shared = AVAudioSession.sharedInstance()
        let options: AVAudioSession.CategoryOptions = [.defaultToSpeaker, .allowBluetooth, .allowAirPlay, .allowBluetoothA2DP]
        Ext.debug("Set playAndRecord start | => \(options) category: \(shared.category) | options \(shared.categoryOptions)")
        guard shared.category != .playAndRecord || shared.categoryOptions != options  else {
            Ext.debug("no need to set playAndRecord")
            return
        }
        setCategory(.playAndRecord, mode: .default, options: options)
        Ext.debug("Set playAndRecord end. category: \(shared.category) | options \(shared.categoryOptions)")
    }
    
    /// 支持后台播放，不受锁屏和静音键影响
    func playback() {
        let shared = AVAudioSession.sharedInstance()
        let options: AVAudioSession.CategoryOptions = [.defaultToSpeaker, .allowBluetooth, .allowAirPlay, .allowBluetoothA2DP]
        Ext.debug("Set playback start | => \(options)")
        guard shared.category != .playback || shared.categoryOptions != options  else {
            Ext.debug("no need to set playback category: \(shared.category) | options \(shared.categoryOptions)")
            return
        }
        setCategory(.playback, mode: .moviePlayback, options: options)
        Ext.debug("Set playback end. category: \(shared.category) | options \(shared.categoryOptions)")
    }
    
    /// 设置音频模式
    func setCategory(_ category: AVAudioSession.Category,
                     mode: AVAudioSession.Mode,
                     options: AVAudioSession.CategoryOptions = []) {
        do {
            let shared = AVAudioSession.sharedInstance()
            try shared.setCategory(category, mode: mode, options: options)
            try shared.setActive(true)
        } catch {
            Ext.debug("set Audio \(category.rawValue) | \(options.rawValue) failure \(error.localizedDescription)")
        }
    }
}
