//
//  LocalPlayer.swift
//  Ext
//
//  Created by naijoug on 2021/3/24.
//

import Foundation
import AVFoundation

public protocol PlayerDelegate: AnyObject {
    func player(_ player: Player, status: Player.Status)
    func player(_ player: Player, timeStatus status: Player.TimeStatus)
}

open class Player: NSObject {
    /// 播放状态
    public enum Status: Equatable {
        case readyToPlay                    // 准备好播放 (资源加载成功)
        case playing(_ time: TimeInterval)  // 播放中
        case paused                         // 暂停播放
        case playEnd                        // 播放结束
    }
    /// 播放时间状态
    public enum TimeStatus {
        case boundary(_ time: TimeInterval) // 播放到边界时间点
        case periodic(_ time: TimeInterval) // 播放到周期时间点
    }
    public weak var delegate: PlayerDelegate?
    
// MARK: - Status
    
    public var logEnabled: Bool = false
    
    open var status: Status = .paused {
        didSet {
            guard oldValue != status else { return }
            Ext.debug("status: \(oldValue) -> \(status)", logEnabled: logEnabled)
            delegate?.player(self, status: status)
        }
    }
    
    /// 播放状态
    public var isPlaying: Bool {
        switch status {
        case .playing: return true
        default: return false
        }
    }
}

/// 播放器
open class LocalPlayer: Player {
    
    deinit {
        clear()
        Ext.debug("")
    }
    
// MARK: - Player
    
    public private(set) var avPlayer = AVPlayer()
    private var boundaryObserver: Any?  // 边界监听
    private var periodicObserver: Any?  // 周期监听
    
// MARK: - Params
    
    /// 资源 URL
    public var url: URL? {
        didSet {
            guard let url = url else { return }
            self.playerItem = AVPlayerItem(asset: AVURLAsset(url: url))
        }
    }
    /// 资源 Item
    public var playerItem: AVPlayerItem? {
        willSet {
            if newValue == nil {
                removeItemObservers()
            }
        }
        didSet {
            addItemObservers()
            avPlayer.replaceCurrentItem(with: playerItem)
            
            guard playerItem != nil else { return }
            status = .readyToPlay
        }
    }
    
    /// 监听边界时间点
    public var boundaryTimes: [NSValue]? {
        didSet {
            addBoundaryObserver()
        }
    }
    /// 周期监听时间 (单位: s)
    public var periodicTime: TimeInterval? {
        didSet {
            addPeriodicObserver()
        }
    }
    
// MARK: - Status
    
    /// 是否循环播放
    private var isLoop: Bool = false
    
    /// 当前时间 (单位: 秒)
    public var currentTime: TimeInterval {
        get {
            let time = CMTimeGetSeconds(avPlayer.currentTime())
            return (time.isNaN || time.isInfinite) ? 0 : time
        }
        set {
            let newTime = CMTimeMakeWithSeconds(newValue, preferredTimescale: playerItem?.asset.duration.timescale ?? 600)
            Ext.debug("newTime: \(newTime) | \(newTime.seconds)", logEnabled: logEnabled)
            avPlayer.seek(to: newTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        }
    }
    
    /// 是否静音🔇
    public var isMuted: Bool = false {
        didSet {
            guard avPlayer.isMuted != isMuted else { return }
            avPlayer.isMuted = isMuted
        }
    }
}

// MARK: - Public

public extension LocalPlayer {
    /// 播放进度
    var progress: Float {
        guard duration > 0 else { return 0.0 }
        return Float(currentTime/duration)
    }
    /// 资源总时长
    var duration: TimeInterval {
        guard let currentItem = avPlayer.currentItem else { return 0.0 }
        let time = CMTimeGetSeconds(currentItem.duration)
        return (time.isNaN || time.isInfinite) ? 0.0 : time
    }
    
    /// seek 到指定时间点
    func seek(_ time: TimeInterval?) {
        guard let time = time else { return }
        currentTime = time
    }
    
    /// 播放
    /// - Parameter time: 指定播放时间点 (秒)
    func play(_ time: TimeInterval? = nil) {
        seek(time)
        Ext.debug("currentTime: \(currentTime) | duration: \(duration)", logEnabled: logEnabled)
        // 播放到了最后，设置到开头
        if duration > 0, currentTime == duration {
            currentTime = 0
        }
        avPlayer.play()
        status = .playing(currentTime)
    }
    /// 暂停播放
    /// - Parameter time: 指定暂停时间点 (秒)
    func pause(_ time: TimeInterval? = nil) {
        seek(time)
        avPlayer.pause()
        status = .paused
    }
    /// 暂停或播放
    func playOrPause() {
        isPlaying ? self.pause() : self.play()
    }
    /// 循环播放
    func loop() {
        isLoop = true
        self.play()
    }
    
    /// 清空
    func clear() {
        avPlayer.pause()
        
        url = nil
        playerItem = nil
        periodicTime = nil
        boundaryTimes = nil
    }
}

// MARK: - Observer

private extension LocalPlayer {
    /// 添加边界监听
    func addBoundaryObserver() {
        // 先移除
        if let boundaryObserver = boundaryObserver {
            avPlayer.removeTimeObserver(boundaryObserver)
            self.boundaryObserver = nil
        }
        /// 时间点监听
        guard let times = boundaryTimes, times.count > 0 else { return }
        boundaryObserver = avPlayer.addBoundaryTimeObserver(forTimes: times, queue: DispatchQueue.main) { [weak self] in
            guard let `self` = self, self.isPlaying else { return }
            self.delegate?.player(self, timeStatus: .boundary(self.currentTime))
        }
    }
    /// 添加周期监听
    func addPeriodicObserver() {
        // 先移除
        if let periodicObserver = periodicObserver {
            avPlayer.removeTimeObserver(periodicObserver)
            self.periodicObserver = nil
        }
        // 添加周期监听
        guard let periodicTime = periodicTime, periodicTime > 0 else { return }
        let interval = CMTimeMakeWithSeconds(periodicTime, preferredTimescale: 600)
        periodicObserver = avPlayer.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [weak self] time in
            guard let `self` = self, self.isPlaying else { return }
            //Ext.debug("status: \(self.status)")
            self.delegate?.player(self, timeStatus: .periodic(time.seconds))
        }
    }
    
    /// 添加视频资源属性监听
    func addItemObservers() {
        if let item = playerItem {
            NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidPlayToEnd(_:)), name: .AVPlayerItemDidPlayToEndTime, object: item)
        }
    }
    /// 移除资源属性监听
    func removeItemObservers() {
        if let item = playerItem {
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: item)
        }
    }
    @objc
    private func playerItemDidPlayToEnd(_ noti: Notification) {
        guard status != .playEnd else { return }
        status = .playEnd
        if isLoop {
            self.play(0)
        }
    }
}
