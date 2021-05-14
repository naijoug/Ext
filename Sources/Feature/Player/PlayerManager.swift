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
    
    public var logEnabled: Bool = true
    
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
        Ext.debug("\(message) category: \(shared.category) | options \(shared.categoryOptions)", logEnabled: logEnabled, location: false)
    }
}

private extension PlayerManager {
    
    private func log(_ msg: String) {
        guard logEnabled else { return }
        Ext.debug(msg, location: false)
    }
    
    @objc
    func routeChange(_ noti: Notification) {
        guard let reasonValue = noti.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }
        log("reason: \(reason)")
        switch reason {
        case .newDeviceAvailable:
            log("newDeviceAvailable")
            for output in AVAudioSession.sharedInstance().currentRoute.outputs where output.portType == .headphones {
                log("headphone plugged in")
                break
            }
        case .oldDeviceUnavailable:
            log("oldDeviceUnavailable")
            guard let previousRoute = noti.userInfo?[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription else { return }
            log("previousRoute: \(previousRoute)")
            for output in previousRoute.outputs where output.portType == .headphones {
                /**
                 拔出耳机时:
                    1> 系统默认会把输出设备设置为扬声器
                    2> 但是 Category 为 playAndRecord 时，则会把输入设备设置为听筒
                 */
                log("headphone pulled out")
                break
            }
        default: break
        }
        let route = AVAudioSession.sharedInstance().currentRoute
        log("currentRoute: \(route)")
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
