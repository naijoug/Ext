//
//  BaseRecorder.swift
//  Ext
//
//  Created by guojian on 2021/11/23.
//

import Foundation

public enum RecordAction {
    case inRecording(_ duration: Int64)
    case reachedMaxDuration
    case failure(_ error: Error)
}

/// 录制器协议
public protocol Recorder {
    /// 开始录制
    /// - Parameter path: 录制资源保存路径
    /// - Parameter maxDuration: 最大录制时长
    func startRecording(_ path: String, maxDuration: Int64, handler: Ext.DataHandler<RecordAction>?)
    /// 结束录制 (返回录制资源路径)
    func stopRecording(_ handler: Ext.DataHandler<String>?)
}

/// 录制器 ⏺ 基类
open class BaseRecorder: NSObject, ExtLogable {
    public var logEnabled: Bool = true
    public var logLocated: Bool = false
    
    /// 录制定时器 ⏰
    private weak var timer: Timer?
    /// 录制时长
    private var duration: Int64 = 0
    
    /// 最大录制时长
    private var maxDuration: Int64 = 0
    /// 录制事件回调
    public private(set) var recordHandler: Ext.DataHandler<RecordAction>?
    
    deinit {
        stopTimer()
    }
    
    /// 是否使用定时器 (如果子类录制已经有定时器，可以设为 false)
    open var timerEnabled: Bool { true }
    
    /// 开始录制 (子类实现特定开始录制操作)
    open func startRecord(_ path: String) -> Bool {
        fatalError("subclass must implement.")
    }
    /// 停止录制 (子类实现特定停止录制操作)
    open func stopRecord(_ handler: Ext.DataHandler<String>? = nil) {
        fatalError("subclass must implement.")
    }
}

extension BaseRecorder: Recorder {
    
    /// 开始⏺录制
    public func startRecording(_ path: String, maxDuration: Int64, handler: Ext.DataHandler<RecordAction>?) {
        self.maxDuration = maxDuration
        self.recordHandler = handler
        ext.log("start record duration: \(TimeInterval(self.maxDuration / 1000_000)) | \(self.maxDuration) | path: \(path)")
        
        let url = URL(fileURLWithPath: path)
        // 如果文件已存在，先删除
        FileManager.default.ext.remove(url)
        // 如果文件所在文件夹不存在，创建
        FileManager.default.ext.createIfNotExists(url.deletingLastPathComponent())
        
        guard startRecord(path) else {
            ext.log("start record failed.")
            handler?(.failure(Ext.Error.inner("start record failed.")))
            return
        }
        ext.log("start record succeeded")
        startTimer()
    }
    
    /// 停止⏹录制
    public func stopRecording(_ handler: Ext.DataHandler<String>?) {
        ext.log("stop record.")
        stopRecord(handler)
        stopTimer()
    }
    
}

// MARK: - Timer

extension BaseRecorder {
    
    /// 开启定时器
    private func startTimer() {
        guard timerEnabled else { return }
        ext.log("开启录制定时器")
        stopTimer()
        // 定时器时间间隔: 0.1s
        let interval: TimeInterval = 0.1
        let timer = Timer(timeInterval: interval, repeats: true, block: { [weak self] _ in
            guard let self else { return }
            self.duration += Int64(interval * 1000_000)
            
            guard self.duration < self.maxDuration else {
                self.ext.log("达到最大录制时长")
                self.recordHandler?(.reachedMaxDuration)
                return
            }
            self.timerAction()
            self.recordHandler?(.inRecording(self.duration))
        })
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
    /// 停止定时器
    private func stopTimer() {
        guard timerEnabled else { return }
        guard timer != nil else { return }
        timer?.invalidate()
        timer = nil
        duration = 0
        ext.log("停止录制定时器")
    }
    
    @objc
    func timerAction() {}
}
