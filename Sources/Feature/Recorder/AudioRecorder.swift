//
//  AudioRecorder.swift
//  Ext
//
//  Created by guojian on 2021/4/6.
//

import Foundation
import AVFoundation

/// 音频录制器
public class AudioRecorder: BaseRecorder {
    
    /// 录音器
    private var recorder: AVAudioRecorder?
    
    /// 音量级别测量是否可用
    public var isMeteringEnabled: Bool = true
    /// 音量级别测量回调
    public var levelHandler: Ext.DataHandler<CGFloat>?
    
// MARK: - Override
    
    public override func startRecord(_ path: String) -> Bool {
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            let audioRecorder = try AVAudioRecorder(url: URL(fileURLWithPath: path), settings: settings)
            self.recorder = audioRecorder
            audioRecorder.isMeteringEnabled = isMeteringEnabled
            audioRecorder.delegate = self
            audioRecorder.record()
            
            return true
        } catch {
            Ext.debug("start audio recording failed.", error: error)
            self.recordHandler?(.failure(error))
            return false
        }
    }
    public override func stopRecord(_ handler: Ext.DataHandler<String>? = nil) {
        Ext.debug("stop audio record \(recorder?.url.path ?? "").")
        
        guard let recorder = recorder else { return }
        recorder.stop()
        let path = recorder.url.path
        self.recorder = nil
        handler?(path)
        
        if isMeteringEnabled {
            self.levelHandler?(0)
        }
        Ext.debug("stop audio record succeeded", tag: .bingo)
    }
    
    override func timerAction() {
        guard isMeteringEnabled, let recorder = recorder else { return }
        recorder.updateMeters()
        let average = recorder.averagePower(forChannel: 0) // 均值分贝
        let db = CGFloat(pow(10, (0.06 * average))) // 分贝
        //Ext.debug("average: \(average) | db: \(db)")
        self.levelHandler?(db)
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {
    
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Ext.debug("finish audio recording, \(flag)")
        if !flag { // 录制失败
            stopRecording(nil)
        }
    }
    
}
