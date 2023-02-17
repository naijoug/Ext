//
//  AudioSession.swift
//  Ext
//
//  Created by guojian on 2022/2/24.
//

import Foundation
import AVFoundation

private var AudioSessionCategoryContext = 0

/**
 Reference:
    - [AVAudioSession bluetooth support](http://devmonologue.com/tutorials/avaudiosession-bluetooth-support/)
    - [AudioSessionProgrammingGuide](https://developer.apple.com/library/archive/documentation/Audio/Conceptual/AudioSessionProgrammingGuide)
    - https://developer.apple.com/library/archive/qa/qa1799/_index.html
 */

/// 音频 Session
public final class AudioSession {
    public static let shared = AudioSession()
    
    private let avSession = AVAudioSession.sharedInstance()
    
    private var observers = [NSKeyValueObservation?]()
    
    private init() {
        addObservers()
        addNotification()
    }
    deinit {
        removeNotfication()
        removeObservers()
    }
    
    public var logEnabled: Bool = true
    
    /// 初始化
    public func setup() {
        Ext.debug("availableCategories: \(avSession.availableCategories.map({ $0.rawValue }))", tag: .debug, logEnabled: logEnabled)
        Ext.debug("availableModes: \(avSession.availableModes.map({ $0.rawValue }))", tag: .debug, logEnabled: logEnabled)
        Ext.debug("default: \(avSession)", tag: .debug, logEnabled: logEnabled)
    }
}

// MARK: - Notification

private extension AudioSession {
    
    func addObservers() {
        observers.append(avSession.observe(\.category, options: [.initial, .new]) { _, change in
            Ext.debug("changed category: \(change))", tag: .fire, logEnabled: self.logEnabled)
        })
        observers.append(avSession.observe(\.mode, options: [.initial, .new], changeHandler: { _, change in
            Ext.debug("changed mode: \(change)", tag: .fire, logEnabled: self.logEnabled)
        }))
        observers.append(avSession.observe(\.categoryOptions, options: [.initial, .new], changeHandler: { _, change in
            Ext.debug("changed options: \(change)", tag: .fire, logEnabled: self.logEnabled)
        }))
    }
    func removeObservers() {
        for observer in observers {
            observer?.invalidate()
        }
        observers.removeAll()
    }
    
    func addNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(routeChange(_:)), name: AVAudioSession.routeChangeNotification, object: nil)
    }
    func removeNotfication() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc
    func routeChange(_ noti: Notification) {
        guard let reasonValue = noti.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }
        
        Ext.debug("routeChange reason: \(reason)", logEnabled: logEnabled)
        switch reason {
        case .newDeviceAvailable:
            let previousRoute = noti.userInfo?[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription
            let newInputs = avSession.currentRoute.inputs.filter { !(previousRoute?.inputs.contains($0) ?? false) }
            let newOutputs = avSession.currentRoute.outputs.filter { !(previousRoute?.outputs.contains($0) ?? false) }
            Ext.debug("\(String(describing: previousRoute)) -> \(avSession.currentRoute)", logEnabled: logEnabled)
            Ext.debug("new inputs: \(newInputs) | new outputs: \(newOutputs)")
            
            for output in newOutputs {
                switch output.portType {
                case .headphones:
                    Ext.debug("headphone plugged in", tag: .custom("🎧"), logEnabled: logEnabled)
                case .bluetoothHFP:
                    Ext.debug("bluetooth connected", tag: .custom("🌶"), logEnabled: logEnabled)
                default: ()
                }
            }
        case .oldDeviceUnavailable:
            guard let previousRoute = noti.userInfo?[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription else { return }
            let oldInputs = previousRoute.inputs.filter { !avSession.currentRoute.inputs.contains($0) }
            let oldOutputs = previousRoute.outputs.filter { !avSession.currentRoute.outputs.contains($0) }
            Ext.debug("previous route: \(previousRoute)", logEnabled: logEnabled)
            Ext.debug("old inputs: \(oldInputs) | old outputs: \(oldOutputs)")
            for output in oldOutputs {
                switch output.portType {
                    /**
                     拔出耳机时:
                        1> 系统默认会把输出设备设置为扬声器
                        2> 但是 Category 为 playAndRecord 时，则会把输入设备设置为听筒
                     */
                case .headphones:
                    Ext.debug("headphone pulled out", tag: .custom("🎧"), logEnabled: logEnabled)
                case .bluetoothHFP, .bluetoothA2DP:
                    Ext.debug("bluetooth disconnected.", tag: .custom("🌶"), logEnabled: logEnabled)
                default: ()
                }
            }
        case .categoryChange:
            Ext.debug("audio session category changed.", tag: .replay)
        default: break
        }
        Ext.debug("\(avSession)", tag: .audio, logEnabled: logEnabled)
    }
}

// MARK: - Private

private extension AudioSession.Kind {
    /**
        - ambient:
        - soloAmbient:      
        - playback:         播放
        - record:           录制
        - playAndRecord:    播放录制
        - multiRoute:       
     */
    var avCategory: AVAudioSession.Category {
        switch self {
        case .playback:         return .playback
        case .playAndRecord:    return .playAndRecord
        }
    }
    /**
        - default:          默认模式，兼容所有 category
        - voiceChat:
        - gameChat:         
        - videoRecording:   视频录制模式
        - measurement:
        - moviePlayback:
        - videoChat:
        - spokenAudio:      [iOS9]
        - voicePrompt:      [iOS12]
     */
    var avMode: AVAudioSession.Mode {
        switch self {
        case .playback:         return .default
        case .playAndRecord:    return .default
        }
    }
    /**
        - mixWithOthers:        (输出) 
        - duckOthers:           (输出)
        - allowBluetooth:       (输入&输出) 支持蓝牙设备
        - defaultToSpeaker:     (输出) 播放录制模式下，默认输出为听筒，这个选项用将输出声音外放
        - interruptSpokenAudioAndMixWithOthers:
        - allowBluetoothA2DP:   (输出) 支持 A2DP 蓝牙设备
        - allowAirPlay:         (输出) AirPlay 设备 <PlayAndRecord>
     */
    var avOptions: AVAudioSession.CategoryOptions {
        switch self {
        case .playback:         return []
        case .playAndRecord:    return [.defaultToSpeaker, .allowBluetooth]
        }
    }
}

// MARK: - Public

public extension AudioSession {
    
    /// 常用的音频种类
    enum Kind {
        /// 播放模式
        case playback
        /// 播放录制模式
        case playAndRecord
    }
    
    /// 激活音频分类
    func active(_ kind: Kind) {
        let session = AVAudioSession.sharedInstance()
        Ext.debug("set \(kind) begin...", tag: .begin, logEnabled: logEnabled)
        guard session.category != kind.avCategory || session.categoryOptions != kind.avOptions  else {
            Ext.debug("no need to set \(kind)", logEnabled: logEnabled)
            return
        }
        Ext.debug("\(session.category) -> \(kind.avCategory)", tag: .fire, logEnabled: logEnabled)
        do {
            //if category == .playAndRecord, #available(iOS 13.0, *) {
            //    try session.setAllowHapticsAndSystemSoundsDuringRecording(true)
            //}
            try session.setCategory(kind.avCategory, mode: kind.avMode, options: kind.avOptions)
            try session.setActive(true)
            
            //if kind == .playAndRecord { try setPreferredInput() }
        } catch {
            Ext.debug("set \(kind) failed.", error: error, tag: .failure, logEnabled: Ext.logEnabled)
        }
        Ext.debug("set \(kind) end.", tag: .end, logEnabled: logEnabled)
    }
    
    /// 设置最优输入设备
    private func setPreferredInput() throws {
        // 输入设备优先级
        var inputsPriority: [(type: AVAudioSession.Port, input: AVAudioSessionPortDescription?)] = [
            (.headsetMic, nil),     // 1. 有线耳机
            (.bluetoothHFP, nil),   // 2. 蓝牙(无线)耳机
            (.builtInMic, nil)      // 3. 手机麦克风
        ]
        let session = AVAudioSession.sharedInstance()
        for availableInput in session.availableInputs ?? [] {
            guard let index = inputsPriority.firstIndex(where: { $0.type == availableInput.portType }) else { continue }
            inputsPriority[index].input = availableInput
        }
        guard let input = inputsPriority.filter({ $0.input != nil }).first?.input else {
            fatalError("no avalible input")
        }
        try session.setPreferredInput(input)
        Ext.debug("set preferred input: \(input)", logEnabled: logEnabled)
    }
    
    /// 强制音频输出为扬声器🔈
    func overrideSpeaker() {
        do {
            try avSession.overrideOutputAudioPort(.speaker)
            Ext.debug("override output to speaker.", logEnabled: logEnabled)
        } catch {
            Ext.debug("overrride ouput to speaker failed.", error: error, logEnabled: Ext.logEnabled)
        }
    }
}

// MARK: - Log

extension NSKeyValueObservedChange: CustomStringConvertible {
    public var description: String {
        var msg = ""
        msg += "\(String(describing: oldValue)) => \(String(describing: newValue))"
        return msg
    }
}

extension AudioSession.Kind: CustomStringConvertible {
    public var description: String {
        "{category: \(avCategory) | mode: \(avMode) | options: \(avOptions)}"
    }
}

extension AVAudioSession {
    open override var description: String {
        var msg = "{"
        msg += "category: \(category)"
        msg += ", options \(categoryOptions)"
        msg += ", isInputAvailable: \(isInputAvailable)"
        msg += ", currentRoute: \(currentRoute)"
        //msg += ", availableInputs: \(availableInputs ?? [])"
        //if let preferredInput = preferredInput { msg += ", preferredInput: \(preferredInput)" }
        //msg += ", preferredOutputNumberOfChannels: \(preferredOutputNumberOfChannels)"
        //msg += ", preferredInputNumberOfChannels: \(preferredInputNumberOfChannels)"
        if let inputDataSource = inputDataSource { msg += ", inputDataSource: \(inputDataSource)" }
        if let inputDataSources = inputDataSources { msg += ", inputDataSources: \(inputDataSources)" }
        if let outputDataSource = outputDataSource { msg += ", outputDataSource: \(outputDataSource)" }
        if let outputDataSources = outputDataSources { msg += ", outputDataSources: \(outputDataSources)" }
        msg += "}"
        return msg
    }
}

extension AVAudioSession.Category: CustomStringConvertible {
    public var description: String {
        switch self {
        case .ambient:          return "ambient"
        case .soloAmbient:      return "soloAmbient"
        case .playback:         return "playback"
        case .playAndRecord:    return "playAndRecord"
        case .record:           return "record"
        case .multiRoute:       return "multiRoute"
        default: return "\(self.rawValue)"
        }
    }
}
extension AVAudioSession.Mode: CustomStringConvertible {
    public var description: String {
        switch self {
        case .default:          return "default"
        case .voiceChat:        return "voiceChat"
        case .gameChat:         return "gameChat"
        case .videoRecording:   return "videoRecording"
        case .measurement:      return "measurement"
        case .moviePlayback:    return "moviePlayback"
        case .videoChat:        return"videoChat"
        case .spokenAudio:      return "spokenAudio"
        default: return "\(self.rawValue)"
        }
    }
}
extension AVAudioSession.CategoryOptions: CustomStringConvertible {
    
    // refrence: https://stackoverflow.com/questions/42588375/how-to-display-optionset-values-in-human-readable-form
    
    public var description: String {
        let options: [(AVAudioSession.CategoryOptions, String)] = [
            (.mixWithOthers,        "mixWithOthers"),
            (.duckOthers,           "duckOthers"),
            (.allowBluetooth,       "allowBluetooth"),
            (.defaultToSpeaker,     "defaultToSpeaker"),
            (.interruptSpokenAudioAndMixWithOthers, "interruptSpokenAudioAndMixWithOthers"),
            (.allowBluetoothA2DP,   "allowBluetoothA2DP"),
            (.allowAirPlay,         "allowAirPlay")
        ]
        return "\(options.filter { contains($0.0) }.map { $0.1 })"
    }
}

extension AVAudioSessionRouteDescription {
    open override var description: String {
        "{🎤 : \(inputs) | 🎧 : \(outputs)}"
    }
}
extension AVAudioSessionPortDescription {
    open override var description: String {
        "{\(portType) : \"\(portName)\"}"
    }
}
extension AVAudioSession.Port: CustomStringConvertible {
    public var description: String {
        switch self {
        case .lineIn:           return "lineIn"
        case .builtInMic:       return "builtInMic"
        case .headsetMic:       return "headsetMic"
        case .lineOut:          return "lineOut"
        case .headphones:       return "headphones"
        case .bluetoothA2DP:    return "bluetoothA2DP"
        case .builtInReceiver:  return "builtInReceiver"
        case .builtInSpeaker:   return "builtInSpeaker"
        case .HDMI:             return "HDMI"
        case .airPlay:          return "airPlay"
        case .bluetoothLE:      return "bluetoothLE"
        case .bluetoothHFP:     return "bluetoothHFP"
        case .usbAudio:         return "usbAudio"
        case .carAudio:         return "carAudio"
        default: return "\(self.rawValue)"
        }
    }
}

extension AVAudioSessionDataSourceDescription {
    open override var description: String {
        "{\(dataSourceID) : \(dataSourceName)}"
    }
}

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
