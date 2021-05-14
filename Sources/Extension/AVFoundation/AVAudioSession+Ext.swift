//
//  AVAudioSession+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/5/14.
//

import AVFoundation

extension AVAudioSessionRouteDescription {
    open override var description: String {
        var msg = ""
        msg += "\n\t🎤 : \(inputs)"
        msg += "\n\t🎧 : \(outputs)"
        return msg
    }
}

public extension ExtWrapper where Base == AVAudioSession {
    
    /// 是否连接耳机输出
    var isHandphoneOuput: Bool {
        let route = AVAudioSession.sharedInstance().currentRoute
        for output in route.outputs {
            Ext.debug("output: \(output)")
            switch output.portType {
            case .headphones, .bluetoothHFP, .bluetoothA2DP:
                return true
            default: break
            }
        }
        return false
    }
    
    /// 是否为蓝牙设备输入 (AirPods、蓝牙🎧、...)
    var isBluetoothInput: Bool {
        let route = AVAudioSession.sharedInstance().currentRoute
        for input in route.inputs {
            Ext.debug("input: \(input)")
            switch input.portType {
            case .bluetoothHFP:
                return true
            default: break
            }
        }
        return false
    }
    
}
