//
//  ExtPlayer.swift
//  Ext
//
//  Created by naijoug on 2020/11/4.
//

import AVKit
import AVFoundation


/**
 Reference:
    - https://developer.apple.com/documentation/avfoundation/media_playback_and_selection
    - https://stackoverflow.com/questions/38867190/how-can-i-check-if-my-avplayer-is-buffering
 */

public protocol ExtPlayerDelegate: AnyObject {
    func extPlayer(_ player: ExtPlayer, status: ExtPlayer.Status)
    func extPlayer(_ player: ExtPlayer, timeStatus status: ExtPlayer.TimeStatus)
    func extPlayer(_ player: ExtPlayer, bufferStatus status: ExtPlayer.BufferStatus)
}

public class ExtPlayer: NSObject {
    /// 播放状态
    public enum Status: Equatable {
        public static func == (lhs: ExtPlayer.Status, rhs: ExtPlayer.Status) -> Bool {
            return lhs.description == rhs.description
        }
        
        case unknown                // 未知状态 (还未加载任何播放资源)
        case readyToPlay            // 准备好播放
        case playing                // 正在播放
        case paused                 // 暂停播放
        case playToEnd              // 播放完成
        case failed(_ error: Error) // 播放失败
    }
    /// 播放器缓存状态
    public enum BufferStatus {
        case unknown                // 未知状态
        case buffering              // 正在缓冲 (不能播放)
        case bufferToReady          // 缓冲准备好，可以播放
        case bufferToEnd            // 缓冲完成
    }
    /// 播放器时间状态
    public enum TimeStatus {
        case buffer(_ time: TimeInterval, _ duration: TimeInterval)
        case periodic(_ time: TimeInterval, _ duration: TimeInterval)
        case boundary(_ time: TimeInterval, _ duration: TimeInterval)
    }
    public weak var delegate: ExtPlayerDelegate?
    
// MARK: - Status
    
    /// 日志标识
    public var logEnabled: Bool = false
    /// 时间监听回调日志
    public var timeLogEnabled: Bool = false
    
    /// 播放状态
    private(set) var status: ExtPlayer.Status = .unknown {
        didSet {
            guard status != oldValue else { return }
            Ext.debug("\(oldValue) ===> \(status)", logEnabled: logEnabled)
            delegate?.extPlayer(self, status: status)
        }
    }
    /// 缓冲状态
    private(set) var bufferStatus: ExtPlayer.BufferStatus = .unknown {
        didSet {
            guard bufferStatus != oldValue else { return }
            Ext.debug("\(oldValue) -> \(bufferStatus)", logEnabled: logEnabled)
            delegate?.extPlayer(self, bufferStatus: bufferStatus)
        }
    }
    
    /// 是否正在 seek 播放时间
    public private(set) var isSeeking: Bool = false
    
    /// 是否静音🔇
    public var isMuted: Bool = false {
        didSet {
            guard avPlayer.isMuted != isMuted else { return }
            avPlayer.isMuted = isMuted
        }
    }
    
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
    
    /// AVPlayer
    public let avPlayer = AVPlayer()
    
    public override init() {
        super.init()
        
        addPlayerObservers()
        addItemObservers()
    }
    deinit {
        clear()
        Ext.debug("")
    }
    
// MARK: - Params
    
    /// 播放资源 Url
    public var playerUrl: URL? {
        didSet {
            guard let url = playerUrl else {
                status = .failed(Ext.Error.inner("player url is nil."))
                return
            }
            playerItem = AVPlayerItem(asset: AVURLAsset(url: url))
        }
    }
    
    /// 播放资源 Item
    public var playerItem: AVPlayerItem? {
        didSet {
            Ext.debug("\(String(describing: oldValue)) -> \(String(describing: playerItem))", logEnabled: logEnabled)
            func addNotifications() {
                if let item = oldValue {
                    NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: item)
                    NotificationCenter.default.removeObserver(self, name: .AVPlayerItemFailedToPlayToEndTime, object: item)
                }
                guard let item = playerItem else { return }
                NotificationCenter.default.addObserver(self, selector: #selector(didPlayToEnd(_:)),
                                                       name: .AVPlayerItemDidPlayToEndTime, object: item)
                NotificationCenter.default.addObserver(self, selector: #selector(failedToPlayToEnd(_:)),
                                                       name: .AVPlayerItemFailedToPlayToEndTime, object: item)
            }
            
            addNotifications()
            
            avPlayer.replaceCurrentItem(with: playerItem)
            
            guard playerItem != nil else { return }
            status = .readyToPlay
        }
    }
    
// MARK: - Observer
    
    private var boundaryObserver: Any?  // 边界监听
    private var periodicObserver: Any?  // 周期监听
    /// KVO 监听
    private var playerObservers = [NSKeyValueObservation?]()
    private var itemObservers = [NSKeyValueObservation?]()
    
// MARK: - Handler
    
    /// 时间状态回调
    private var timeHandlers = [Ext.DataHandler<TimeStatus>]()
    /// 播放状态回调
    private var playHandlers = [Ext.DataHandler<Bool>]()
}

extension ExtPlayer {
    /// 添加时间状态回调
    public func addTimeHandler(_ handler: @escaping Ext.DataHandler<TimeStatus>) {
        timeHandlers.append(handler)
    }
    private func handleTime(_ status: TimeStatus) {
        Ext.debug("\(status)", logEnabled: timeLogEnabled)
        delegate?.extPlayer(self, timeStatus: status)
        
        for handler in timeHandlers {
            handler(status)
        }
    }
    
    /// 添加播放状态回调
    public func addPlayHandler(_ handler: @escaping Ext.DataHandler<Bool>) {
        playHandlers.append(handler)
    }
    private func handlePlay(_ isPlaying: Bool) {
        Ext.debug("avPlayer isPlaying: \(isPlaying) | status: \(self.status) | timeControlStatus: \(avPlayer.timeControlStatus) | \(playHandlers)")
        
        for handler in playHandlers {
            handler(isPlaying)
        }
    }
}

//MARK: - Public

public extension ExtPlayer {
    /// 播放状态
    var isPlaying: Bool {
        switch status {
        case .playing: return true
        default: return false
        }
    }
    /// 缓冲状态
    var isBuffering: Bool {
        switch bufferStatus {
        case .buffering: return true
        default: return false
        }
    }
    
    /// 当前时间 (单位: 秒)
    var currentTime: TimeInterval {
        let time = CMTimeGetSeconds(avPlayer.currentTime())
        return (time.isNaN || time.isInfinite || time < 0) ? 0.0 : time
    }
    /// 当前播放资源总时长
    var duration: TimeInterval? {
        guard let time = avPlayer.currentItem?.duration.seconds else { return nil }
        return (time.isNaN || time.isInfinite || time < 0) ? nil : time
    }
    /// 播放进度
    var progress: Double {
        guard let duration = duration, duration > 0 else { return 0.0 }
        return currentTime/duration
    }
}

public extension ExtPlayer {
    
    func clearData() {
        avPlayer.pause()
        /// 资源清理
        periodicTime = nil
        boundaryTimes = nil
        playerItem?.asset.cancelLoading()
        playerItem?.cancelPendingSeeks()
        playerItem = nil
        
        /// 状态清理
        isSeeking = false
        status = .unknown
        bufferStatus = .unknown
    }
    
    /// 清理
    func clear() {
        // 数据清理
        clearData()
        
        // 回调清理
        timeHandlers.removeAll()
        playHandlers.removeAll()
    }
    
    /// 播放
    func play() {
        Ext.debug("play currentTime: \(currentTime) | duration: \(duration ?? 0)", logEnabled: logEnabled)
        avPlayer.play()
        status = .playing
    }
    /// 暂停播放
    func pause() {
        Ext.debug("pause currentTime: \(currentTime) | duration: \(duration ?? 0)", logEnabled: logEnabled)
        avPlayer.pause()
        status = .paused
    }
    
    /// 调整播放时间点
    /// - Parameters:
    ///   - time: 需要调整到的时间
    ///   - handler: 调整完成回调
    func seek(_ time: TimeInterval?, handler: Ext.ResultVoidHandler?) {
        guard let time = time else {
            Ext.debug("ext player not need to seek", logEnabled: self.logEnabled)
            handler?(.success(()))
            return
        }
        if isPlaying {
            avPlayer.pause()
            Ext.debug("before seeking, player is playing to pause", logEnabled: self.logEnabled)
        }
        let newTime = CMTimeMakeWithSeconds(max(0, time), preferredTimescale: playerItem?.asset.duration.timescale ?? 600)
        Ext.debug("begin seeking newTime: \(newTime) | \(newTime.seconds) | \(time)", tag: .launch, logEnabled: logEnabled)
        isSeeking = true
        avPlayer.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] completion in
            guard let `self` = self else { return }
            self.isSeeking = false
            Ext.debug("end player seeking \(completion) | \(self.currentTime)", error: self.avPlayer.error, tag: .bingo, logEnabled: self.logEnabled)
            guard completion else {
                handler?(.failure(Ext.Error.inner("seek time failure.")))
                return
            }
            handler?(.success(()))
        }
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
            guard let `self` = self, let duration = self.duration else { return }
            Ext.debug("boundary: \(self.currentTime) / \(duration) | playerStatus: \(self.status) | isPlaying: \(self.isPlaying)", logEnabled: self.timeLogEnabled)
            guard self.isPlaying  else { return }
            self.handleTime(.boundary(self.currentTime, duration))
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
            guard let `self` = self, let duration = self.duration else { return }
            Ext.debug("periodic: \(self.currentTime) / \(duration) | playerStatus: \(self.status) | isPlaying: \(self.isPlaying)", logEnabled: self.timeLogEnabled)
            guard self.isPlaying else { return }
            self.handleTime(.periodic(self.currentTime, duration))
        }
    }
    
    @objc
    func didPlayToEnd(_ notification: Notification) {
        guard let item = notification.object as? AVPlayerItem, item == playerItem else { return }
        Ext.debug("didPlayToEnd", logEnabled: logEnabled)
        // play to end, seek to start
        avPlayer.seek(to: .zero)
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
                self.status = .failed(player.error ?? Ext.Error.inner("AVPlayer failed."))
            default: break
            }
        }))
        // timeControlStatus : 播放器时间控制状态
        playerObservers.append(avPlayer.observe(\.timeControlStatus, options: [.initial, .new], changeHandler: { [weak self] player, change in
            guard let `self` = self else { return }
            Ext.debug("player timeControlStatus: \(player.timeControlStatus) | currentTime: \(self.currentTime)", logEnabled: self.logEnabled)
            switch player.timeControlStatus {
            case .waitingToPlayAtSpecifiedRate:
                // 缓冲区域内容不够播放时，变为缓冲状态
                guard !(player.currentItem?.isPlaybackLikelyToKeepUp ?? false) else { return }
                self.bufferStatus = .buffering
            case .playing:
                self.handlePlay(true)
            case .paused:
                self.handlePlay(false)
            default: ()
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
            case .failed: // AVPlayerItem 错误 (播放资源错误)
                self.status = .failed(item.error ?? Ext.Error.inner("player item failed."))
            default: break
            }
        }))
        // isPlaybackBufferEmpty : 当前缓冲区去是否为空 [true: 缓冲区为空，不能播放 | false: 缓冲区不为空，可以播放]
        itemObservers.append(avPlayer.observe(\.currentItem?.isPlaybackBufferEmpty, options: [.new], changeHandler: { [weak self] player, change in
            guard let `self` = self, let isPlaybackBufferEmpty = player.currentItem?.isPlaybackBufferEmpty else { return }
            Ext.debug("isPlaybackBufferEmpty: \(isPlaybackBufferEmpty)", logEnabled: self.logEnabled)
            self.bufferStatus = .buffering
        }))
        // isPlaybackLikelyToKeepUp : 缓冲区内容是否可以播放
        itemObservers.append(avPlayer.observe(\.currentItem?.isPlaybackLikelyToKeepUp, options: [.new], changeHandler: { [weak self] player, change in
            guard let `self` = self, let isPlaybackLikelyToKeepUp = player.currentItem?.isPlaybackLikelyToKeepUp else { return }
            Ext.debug("isPlaybackLikelyToKeepUp: \(isPlaybackLikelyToKeepUp)", logEnabled: self.logEnabled)
            guard isPlaybackLikelyToKeepUp else { return }
            self.bufferStatus = .bufferToReady
        }))
        // loadedTimeRanges : 缓冲区加载的时间范围
        itemObservers.append(avPlayer.observe(\.currentItem?.loadedTimeRanges, options: [.new], changeHandler: { [weak self] player, change in
            guard let `self` = self else { return }
            guard let bufferTimeRange = player.currentItem?.loadedTimeRanges.first?.timeRangeValue, let duration = self.duration else { return }
            // 缓冲到的时间
            let bufferTime = bufferTimeRange.start.seconds  + bufferTimeRange.duration.seconds
            Ext.debug("buffering: \(bufferTime) / \(duration) | \(player.currentItem?.loadedTimeRanges ?? [])", logEnabled: self.timeLogEnabled)
            self.handleTime(.buffer(bufferTime, duration))
        }))
        // isPlaybackBufferFull : 缓冲区是否完成
        itemObservers.append(avPlayer.observe(\.currentItem?.isPlaybackBufferFull, options: [.new], changeHandler: { [weak self] player, change in
            guard let `self` = self, let isPlaybackBufferFull = player.currentItem?.isPlaybackBufferFull else { return }
            Ext.debug("isPlaybackBufferFull: \(isPlaybackBufferFull)", logEnabled: self.logEnabled)
            guard isPlaybackBufferFull else { return }
            self.bufferStatus = .bufferToEnd
        }))
    }
}

// MARK: - Log

extension ExtPlayer {
    public override var description: String {
        var msg = super.description
        msg += " | status: \(status) | bufferStatus: \(bufferStatus) | \(playerItem?.asset.ext.urlString ?? "nil")"
        return msg
    }
}

extension ExtPlayer.Status: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown:              return "unknown"
        case .readyToPlay:          return "readyToPlay"
        case .playing:              return "playing"
        case .paused:               return "paused"
        case .playToEnd:            return "playToEnd"
        case .failed(let error):    return "failed (\(error.localizedDescription))"
        }
    }
}
extension ExtPlayer.BufferStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown:              return "unknown"
        case .buffering:            return "buffering"
        case .bufferToReady:        return "bufferToReady"
        case .bufferToEnd:          return "bufferToEnd"
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
        msg += " | status \(status)"
        msg += " | isPlaybackBufferEmpty: \(isPlaybackBufferEmpty) | isPlaybackLikelyToKeepUp: \(isPlaybackLikelyToKeepUp) | isPlaybackBufferFull: \(isPlaybackBufferFull)"
        msg += " | \(asset.ext.urlString ?? "")"
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
