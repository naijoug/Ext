//
//  ExtPlayer.swift
//  Ext
//
//  Created by naijoug on 2020/11/4.
//

import AVKit
import AVFoundation

extension AVPlayer {
    /// 是否正在播放视频
    var isPlaying: Bool { timeControlStatus == .playing }
}

/**
 Reference:
    - https://developer.apple.com/documentation/avfoundation/media_playback_and_selection
    - https://stackoverflow.com/questions/38867190/how-can-i-check-if-my-avplayer-is-buffering
 */

public protocol ExtPlayerDelegate: AnyObject {
    func extPlayer(_ player: ExtPlayer, status: ExtPlayer.Status)
    func extPlayer(_ player: ExtPlayer, timeStatus status: ExtPlayer.TimeStatus)
}

open class ExtPlayer: NSObject {
    /// 播放状态
    public enum Status: Equatable {
        public static func == (lhs: ExtPlayer.Status, rhs: ExtPlayer.Status) -> Bool {
            return lhs.description == rhs.description
        }
        
        case unknown                // 位置状态 (还未加载任何播放资源)
        case buffering              // 缓冲中
        case readyToPlay            // 准备好播放
        case playing                // 正在播放
        case paused                 // 暂停播放
        case playToEnd              // 播放完成
        case failed(_ error: Error) // 播放失败
    }
    /// 播放器时间状态
    public enum TimeStatus {
        case buffer(_ time: TimeInterval, _ duration: TimeInterval)
        case periodic(_ time: TimeInterval, _ duration: TimeInterval)
        case boundary(_ time: TimeInterval, _ duration: TimeInterval)
    }
    public weak var delegate: ExtPlayerDelegate?
    
// MARK: - Status
    
    /// 是否需要打印日志
    public var logEnabled: Bool = true
    
    /// 播放状态
    private(set) var status: ExtPlayer.Status = .unknown {
        didSet {
            guard status != oldValue else { return }
            Ext.debug("\(oldValue) ===> \(status)", logEnabled: logEnabled)
            delegate?.extPlayer(self, status: status)
        }
    }
    
    /// 是否正在播放
    private(set) var isPlaying: Bool = false
    /// 是否正在 seek 播放时间
    private var isSeeking: Bool = false
    
// MARK: - Public
    
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
    /// 缓冲时间间隔 (默认: 2s)
    public let bufferInterval: TimeInterval = 2.0
    
// MARK: - Init
    
    deinit {
        clear()
        Ext.debug("")
    }
    public override init() {
        super.init()
        
        addPlayerObservers()
        addItemObservers()
    }
    /// 清理
    func clear() {
        avPlayer.pause()
        /// 资源清理
        periodicTime = nil
        boundaryTimes = nil
        playerItem?.asset.cancelLoading()
        playerItem?.cancelPendingSeeks()
        playerItem = nil
        
        /// 状态清理
        isPlaying = false
        isSeeking = false
        status = .unknown
    }
    
// MARK: - Player
    
    public var playerUrl: URL? {
        didSet {
            guard let url = playerUrl else {
                status = .failed(Ext.Error.inner("player url is nil."))
                return
            }
            playerItem = AVPlayerItem(asset: AVURLAsset(url: url))
        }
    }
    
    public var playerItem: AVPlayerItem? {
        didSet {
            avPlayer.replaceCurrentItem(with: playerItem)
            addItemNotifications()
        }
    }
    /// AVPlayer
    public let avPlayer = AVPlayer()
    
    private var boundaryObserver: Any?  // 边界监听
    private var periodicObserver: Any?  // 周期监听
    /// KVO 监听
    private var playerObservers = [NSKeyValueObservation?]()
    private var itemObservers = [NSKeyValueObservation?]()
}

//MARK: - Public

extension ExtPlayer {
    
    /// 当前播放时间
    public var currentTime: TimeInterval? { avPlayer.currentTime().seconds }
    /// 当前播放资源总时长
    public var duration: TimeInterval? {
        guard let time = avPlayer.currentItem?.duration.seconds else { return nil }
        return (time.isNaN || time.isInfinite) ? nil : time
    }
    
    /// 播放进度
    public var progress: Double {
        guard let currentTime = currentTime, let duration = duration,
              duration > 0 else { return 0.0 }
        return currentTime/duration
    }
    
    /// 播放
    open func play() {
        avPlayer.play()
    }
    
    /// 暂停
    open func pause() {
        avPlayer.pause()
    }
    
    /// 从指定时间开始播放
    open func seekTime(_ time: TimeInterval) {
        seekTime(time, completion: nil)
    }
    open func seekTime(_ time: TimeInterval, completion: ((Bool) -> Void)?) {
        guard !time.isNaN, playerItem?.status == .readyToPlay, !isSeeking else {
            completion?(false)
            return
        }
        isSeeking = true
        self.playerItem?.seek(to: CMTimeMakeWithSeconds(time, preferredTimescale: Int32(NSEC_PER_SEC)), completionHandler: { (finished) in
            DispatchQueue.main.async {
                self.isSeeking = false
                completion?(finished)
            }
        })
    }
}

// MARK: - Notification

private extension ExtPlayer {
    /// 添加边界监听
    func addBoundaryObserver() {
        func removeBoundaryObserver() {
            guard let observer = boundaryObserver else { return }
            avPlayer.removeTimeObserver(observer)
            boundaryObserver = nil
        }
        
        removeBoundaryObserver()
        /// 时间点监听
        guard let times = boundaryTimes, times.count > 0 else { return }
        boundaryObserver = avPlayer.addBoundaryTimeObserver(forTimes: times, queue: .main) { [weak self] in
            guard let `self` = self else { return }
            guard let currentTime = self.currentTime, let duration = self.duration else { return }
            Ext.debug("boundary: \(currentTime) / \(duration)", logEnabled: self.logEnabled)
            self.delegate?.extPlayer(self, timeStatus: .boundary(currentTime, duration))
        }
    }
    
    /// 添加周期监听
    func addPeriodicObserver() {
        func removePeriodicObserver() {
            guard let observer = periodicObserver else { return }
            avPlayer.removeTimeObserver(observer)
            periodicObserver = nil
        }
        
        removePeriodicObserver()
        // 添加周期监听
        guard let time = periodicTime, time > 0 else { return }
        periodicObserver = avPlayer.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(time, preferredTimescale: 600), queue: .main) { [weak self] time in
            guard let `self` = self else { return }
            guard let currentTime = self.currentTime, let duration = self.duration else { return }
            Ext.debug("periodic: \(currentTime) / \(duration)", logEnabled: self.logEnabled)
            self.delegate?.extPlayer(self, timeStatus: .periodic(currentTime, duration))
        }
    }
    
    
    /// 添加 playerItem 通知
    func addItemNotifications() {
        func removeItemNotifations() {
            guard let item = playerItem else { return }
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: item)
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemFailedToPlayToEndTime, object: item)
        }
        
        removeItemNotifations()
        guard let item = playerItem else { return }
        NotificationCenter.default.addObserver(self, selector: #selector(didPlayToEnd(_:)),
                                               name: .AVPlayerItemDidPlayToEndTime, object: item)
        NotificationCenter.default.addObserver(self, selector: #selector(failedToPlayToEnd(_:)),
                                               name: .AVPlayerItemFailedToPlayToEndTime, object: item)
    }
    
    @objc
    func didPlayToEnd(_ notification: Notification) {
        guard let item = notification.object as? AVPlayerItem, item == playerItem else { return }
        Ext.debug("didPlayToEnd", logEnabled: logEnabled)
        status = .playToEnd
    }
    @objc
    func failedToPlayToEnd(_ noti: Notification) {
        guard let item = noti.object as? AVPlayerItem, item == playerItem else { return }
        Ext.debug("failedToPlayToEnd", logEnabled: logEnabled)
        status = .failed(item.error ?? Ext.Error.inner("failed to play to end."))
    }
}

// MARK: - KVO

private extension ExtPlayer {
    
    /// 添加 player KVO 监听
    func addPlayerObservers() {
        func removePlayerObservers() {
            for observer in playerObservers {
                observer?.invalidate()
            }
            playerObservers.removeAll()
        }
        
        removePlayerObservers()
        
        // status : 播放器状态
        playerObservers.append(avPlayer.observe(\.status, options: [.new], changeHandler: { [weak self] player, change in
            guard let `self` = self else { return }
            Ext.debug("player status: \(player.status)", logEnabled: self.logEnabled)
            switch player.status {
            case .failed: // AVPlayer 错误
                self.delegate?.extPlayer(self, status: .failed(player.error ?? Ext.Error.inner("AVPlayer failed.")))
            default: break
            }
        }))
        // timeControlStatus : 播放器时间控制状态
        playerObservers.append(avPlayer.observe(\.timeControlStatus, options: [.initial, .new], changeHandler: { [weak self] player, change in
            guard let `self` = self else { return }
            Ext.debug("player timeControlStatus: \(player.timeControlStatus)", logEnabled: self.logEnabled)
            switch player.timeControlStatus {
            case .playing:  self.status = .playing
            case .paused:   self.status = .paused
            case .waitingToPlayAtSpecifiedRate:
                // 缓冲区域内容不够播放时，变为缓冲状态
                guard !(player.currentItem?.isPlaybackLikelyToKeepUp ?? false) else { return }
                self.status = .buffering
            default: break
            }
        }))
    }
    
    /// 添加 playerItem KVO 监听
    func addItemObservers() {
        func removeItemObservers() {
            for observer in itemObservers {
                observer?.invalidate()
            }
            itemObservers.removeAll()
        }
        
        removeItemObservers()
        
        // item status : 播放资源状态
        itemObservers.append(avPlayer.observe(\.currentItem?.status, options: [.new], changeHandler: { [weak self] item, change in
            guard let `self` = self else { return }
            Ext.debug("playerItem status: \(item.status)", logEnabled: self.logEnabled)
            switch item.status {
            case .readyToPlay:
                self.status = .readyToPlay
            case .failed: // AVPlayerItem 错误 (播放资源错误)
                self.status = .failed(item.error ?? Ext.Error.inner("player item failed."))
            default: break
            }
        }))
        // isPlaybackBufferEmpty : 当前缓冲区去是否为空 [true: 缓冲区为空，不能播放 | false: 缓冲区不为空，可以播放]
        itemObservers.append(avPlayer.observe(\.currentItem?.isPlaybackBufferEmpty, options: [.new], changeHandler: { [weak self] player, change in
            guard let `self` = self else { return }
            Ext.debug("isPlaybackBufferEmpty: \(String(describing: player.currentItem?.isPlaybackBufferEmpty))", logEnabled: self.logEnabled)
        }))
        // isPlaybackLikelyToKeepUp : 缓冲区内容是否可以播放
        itemObservers.append(avPlayer.observe(\.currentItem?.isPlaybackLikelyToKeepUp, options: [.new], changeHandler: { [weak self] player, change in
            guard let `self` = self else { return }
            Ext.debug("isPlaybackLikelyToKeepUp: \(String(describing: player.currentItem?.isPlaybackLikelyToKeepUp))", logEnabled: self.logEnabled)
        }))
        // loadedTimeRanges : 缓冲区加载的时间范围
        itemObservers.append(avPlayer.observe(\.currentItem?.loadedTimeRanges, options: [.new], changeHandler: { [weak self] player, change in
            guard let `self` = self else { return }
            guard let bufferTimeRange = player.currentItem?.loadedTimeRanges.first?.timeRangeValue, let duration = self.duration else { return }
            // 缓冲到的时间
            let bufferTime = bufferTimeRange.start.seconds  + bufferTimeRange.duration.seconds
            Ext.debug("buffering: \(bufferTime) / \(duration) | \(player.currentItem?.loadedTimeRanges ?? [])", logEnabled: self.logEnabled)
            self.delegate?.extPlayer(self, timeStatus: .buffer(bufferTime, duration))
        }))
        // isPlaybackBufferFull : 缓冲区是否完成
        itemObservers.append(avPlayer.observe(\.currentItem?.isPlaybackBufferFull, options: [.new], changeHandler: { [weak self] player, change in
            guard let `self` = self else { return }
            Ext.debug("isPlaybackBufferFull: \(String(describing: player.currentItem?.isPlaybackBufferFull))", logEnabled: self.logEnabled)
            // 缓存完成
        }))
    }
}

// MARK: - Log

extension ExtPlayer.Status: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown:              return "unknown"
        case .buffering:            return "buffering"
        case .readyToPlay:          return "readyToPlay"
        case .playing:              return "playing"
        case .paused:               return "paused"
        case .playToEnd:            return "playToEnd"
        case .failed(let error):    return "failed: \(error.localizedDescription)"
        }
    }
}

extension AVPlayer {
    open override var description: String {
        var msg = super.description
        msg += " | status: \(status) | rate: \(rate) | timeControlStatus: \(timeControlStatus)"
        return msg
    }
}
extension AVPlayer.Status: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown:      return "unknown"
        case .readyToPlay:  return "readyToPlay"
        case .failed:       return "failed"
        @unknown default:   return "unknown default"
        }
    }
}
extension AVPlayer.TimeControlStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .paused:                       return "paused"
        case .waitingToPlayAtSpecifiedRate: return "waitingToPlayAtSpecifiedRate"
        case .playing:                      return "playing"
        @unknown default:                   return "unknown default"
        }
    }
}

extension AVPlayerItem {
    open override var description: String {
        var msg = super.description
        msg += " | status \(status) | isPlaybackBufferEmpty: \(isPlaybackBufferEmpty) | isPlaybackLikelyToKeepUp: \(isPlaybackLikelyToKeepUp) | isPlaybackBufferFull: \(isPlaybackBufferFull)"
        return msg
    }
}
extension AVPlayerItem.Status: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown:      return "unknown"
        case .readyToPlay:  return "readyToPlay"
        case .failed:       return "failed"
        @unknown default:   return "unknown default"
        }
    }
}
