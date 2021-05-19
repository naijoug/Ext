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
        addNotification()
        
        let session = AVAudioSession.sharedInstance()
        Ext.debug("availableCategories: \(session.availableCategories.map({ $0.rawValue }))", tag: .custom("📢"))
        Ext.debug("availableModes: \(session.availableModes.map({ $0.rawValue }))", tag: .custom("📢"))
    }
    deinit {
        removeNotfication()
    }
    
    public var logEnabled: Bool = true
    
    /// 是否静音🔇
    public var isMuted: Bool = true
}

// MARK: - Notification

private extension PlayerManager {
    
    func addNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(routeChange(_:)), name: AVAudioSession.routeChangeNotification, object: nil)
    }
    func removeNotfication() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc
    func routeChange(_ noti: Notification) {
        func log(_ msg: String) {
            guard logEnabled else { return }
            Ext.debug(msg, tag: .custom("📣"), location: false)
        }
        
        guard let reasonValue = noti.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }
        log("routeChange reason => \(reason)")
        switch reason {
        case .newDeviceAvailable:
            for output in AVAudioSession.sharedInstance().currentRoute.outputs where output.portType == .headphones {
                log("headphone plugged in")
                break
            }
        case .oldDeviceUnavailable:
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
        case .categoryChange:
            log("audio session category changed.")
        default: break
        }
        log("audio session: \(AVAudioSession.sharedInstance())")
    }
}

public extension PlayerManager {
    
    /**
     Reference:
        - [AVAudioSession bluetooth support](http://devmonologue.com/tutorials/avaudiosession-bluetooth-support/)
     */
    
    enum AudioCategory {
        /// 播放模式
        case playback
        /// 录制模式
        case record
        /// 播放录制模式
        case playAndRecord
        
        var category: AVAudioSession.Category {
            switch self {
            case .playback: return .playback
            case .record: return .record
            case .playAndRecord: return .playAndRecord
            }
        }
        var mode: AVAudioSession.Mode {
            switch self {
            case .playback: return .default
            case .record: return .default
            case .playAndRecord: return .default
            }
        }
        var options: AVAudioSession.CategoryOptions {
            switch self {
            case .playback: return []
            case .record: return [.allowBluetooth]
            case .playAndRecord: return [.defaultToSpeaker, .allowBluetooth]
//            case .playAndRecord: return [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP]
//            case .playAndRecord: return [.allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker]
            }
        }
    }
    
    /// 设置音频分类
    func setAudio(_ category: AudioCategory) {
        let session = AVAudioSession.sharedInstance()
        logAudio("Set \(category) start, options \(category.options.rawValue)")
        guard session.category != category.category || session.categoryOptions != category.options  else {
            Ext.debug("no need to set \(category)", logEnabled: logEnabled, location: false)
            return
        }
        do {
            try session.setCategory(category.category, mode: category.mode, options: category.options)
            if category.category == .playAndRecord {
                var inputsPriority: [(type: AVAudioSession.Port, input: AVAudioSessionPortDescription?)] = [
                    (.headsetMic, nil),
                    (.bluetoothHFP, nil),
                    (.builtInMic, nil),
                ]
                for availableInput in session.availableInputs ?? [] {
                    guard let index = inputsPriority.firstIndex(where: { $0.type == availableInput.portType }) else { continue }
                    inputsPriority[index].input = availableInput
                }
                guard let input = inputsPriority.filter({ $0.input != nil }).first?.input else {
                    fatalError("no avalible input")
                }
                try session.setPreferredInput(input)
                Ext.debug("set preferred input: \(input)")
            }
            try session.setActive(true)
        } catch {
            Ext.debug("set Audio \(category), options: \(category.options.rawValue) failure \(error.localizedDescription)", tag: .failure, logEnabled: logEnabled, location: false)
        }
        logAudio("Set \(category) end.")
    }
    
    /// 打印当前 Audio 设置
    func logAudio(_ message: String = "") {
        let session = AVAudioSession.sharedInstance()
        Ext.debug("\(message) | \(session)", tag: .custom("⚙️"), logEnabled: logEnabled, location: false)
    }
}

// MARK: - Log

extension AVAudioSession.RouteChangeReason: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown:                      return "unknown"
        case .newDeviceAvailable:           return "newDeviceAvailable"
        case .oldDeviceUnavailable:         return "oldDeviceUnavailable"
        case .categoryChange:               return "categoryChange"
        case .override:                     return "override"
        case .wakeFromSleep:                return "wakeFromSleep"
        case .noSuitableRouteForCategory:   return "noSuitableRouteForCategory"
        case .routeConfigurationChange:     return "routeConfigurationChange"
        default: return "none"
        }
    }
}
extension AVAudioSessionRouteDescription {
    open override var description: String {
        var msg = "{"
        msg += "🎤 : \(inputs)"
        msg += ", 🎧 : \(outputs)"
        msg += "}"
        return msg
    }
}
extension AVAudioSessionPortDescription {
    open override var description: String {
        var msg = "{"
        msg += "portType: \(portType.rawValue)"
        msg += ", portName: \(portName)"
        msg += "}"
        return msg
    }
}
extension AVAudioSession {
    open override var description: String {
        var msg = "{"
        msg += "category: \(category.rawValue)"
        msg += ", options \(categoryOptions.rawValue)"
        msg += ", currentRoute: \(currentRoute)"
        msg += ", preferredOutputNumberOfChannels: \(preferredOutputNumberOfChannels)"
        msg += ", preferredInputNumberOfChannels: \(preferredInputNumberOfChannels)"
        msg += ", isInputAvailable: \(isInputAvailable)"
        msg += ", availableInputs: \(availableInputs ?? [])"
        if let preferredInput = preferredInput { msg += ", preferredInput: \(preferredInput)" }
        msg += "}"
        return msg
    }
}
