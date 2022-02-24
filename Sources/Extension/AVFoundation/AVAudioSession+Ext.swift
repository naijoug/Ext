//
//  AVAudioSession+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/5/14.
//

import AVFoundation

public extension ExtWrapper where Base == AVAudioSession {
    
    /// 是否连接耳机输出
    var isHandphoneOuput: Bool {
        let route = AVAudioSession.sharedInstance().currentRoute
        Ext.debug("outputs: \(route.outputs)", locationEnabled: false)
        for output in route.outputs {
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
        Ext.debug("inputs: \(route.inputs)", locationEnabled: false)
        for input in route.inputs {
            switch input.portType {
            case .bluetoothHFP, .bluetoothA2DP:
                return true
            default: break
            }
        }
        return false
    }
    
}
