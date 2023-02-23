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
    - https://github.com/neekeetab/CachingPlayerItem
 */

public protocol ExtPlayerDelegate: AnyObject {
    func extPlayer(_ player: ExtPlayer, status: ExtPlayer.Status)
    func extPlayer(_ player: ExtPlayer, timeStatus status: ExtPlayer.TimeStatus)
    func extPlayer(_ player: ExtPlayer, bufferStatus status: ExtPlayer.BufferStatus)
}

public extension ExtPlayer {
    /// 播放状态
    enum Status: Equatable {
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
    enum BufferStatus {
        case unknown                // 未知状态
        case buffering              // 正在缓冲 (不能播放)
        case bufferToReady          // 缓冲准备好，可以播放
        case bufferToEnd            // 缓冲完成
    }
    /// 播放器时间状态
    enum TimeStatus {
        case buffer(_ time: TimeInterval, _ duration: TimeInterval)
        case periodic(_ time: TimeInterval, _ duration: TimeInterval)
        case boundary(_ time: TimeInterval, _ duration: TimeInterval)
    }
}

public class ExtPlayer: NSObject, ExtLogable {
    /// 日志标识
    public var logEnabled: Bool = false
    /// 时间监听回调日志
    public var timeLogEnabled: Bool = false
    
    
    public weak var delegate: ExtPlayerDelegate?
    
// MARK: - Status
    
    /// 播放状态
    public private(set) var status: ExtPlayer.Status = .unknown {
        didSet {
            guard status != oldValue else { return }
            ext.log("\(oldValue) ===> \(status)")
            delegate?.extPlayer(self, status: status)
        }
    }
    /// 缓冲状态
    public private(set) var bufferStatus: ExtPlayer.BufferStatus = .unknown {
        didSet {
            guard bufferStatus != oldValue else { return }
            ext.log("\(oldValue) -> \(bufferStatus)")
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
        Ext.log("", tag: .recycle)
    }
    
// MARK: - Params
    
    /// 播放资源 Url
    public var playerUrl: URL? {
        didSet {
            guard let url = playerUrl else {
                //status = .failed(Ext.Error.inner("player url is nil."))
                playerItem = nil
                return
            }
            playerItem = AVPlayerItem(asset: AVURLAsset(url: url))
        }
    }
    
    /// 播放资源 Item
    public var playerItem: AVPlayerItem? {
        didSet {
            ext.log("\(String(describing: oldValue)) -> \(String(describing: playerItem))")
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
        ext.log("\(status)", logEnabled: timeLogEnabled)
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
        ext.log("isPlaying: \(isPlaying) | status: \(self.status) | timeControlStatus: \(avPlayer.timeControlStatus) | \(playHandlers)")
        
        for handler in playHandlers {
            handler(isPlaying)
        }
    }
}

//MARK: - Public

public extension ExtPlayer {
    /// 是否可以播放 (playerItem != nil)
    var playEnabled: Bool { avPlayer.currentItem != nil }
    
    /// 播放状态
    var isPlaying: Bool { status == .playing }
    /// 缓冲状态
    var isBuffering: Bool { bufferStatus == .buffering }
    
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
    func play(_ speed: Float = 1.0) {
        ext.log("play currentTime: \(currentTime) | duration: \(duration ?? 0)")
        //avPlayer.play()
        avPlayer.rate = speed
        status = .playing
    }
    /// 暂停播放
    func pause() {
        ext.log("pause currentTime: \(currentTime) | duration: \(duration ?? 0)")
        avPlayer.pause()
        status = .paused
    }
    
    /// 调整播放时间点
    /// - Parameters:
    ///   - time: 需要调整到的时间
    ///   - handler: 调整完成回调
    func seek(_ time: TimeInterval?, handler: Ext.ResultVoidHandler?) {
        guard let time = time else {
            ext.log("ext player not need to seek")
            handler?(.success(()))
            return
        }
        if isPlaying {
            avPlayer.pause()
            ext.log("before seeking, player is playing to pause")
        }
        let newTime = CMTimeMakeWithSeconds(max(0, time), preferredTimescale: playerItem?.asset.duration.timescale ?? 600)
        ext.log("begin seeking newTime: \(newTime) | \(newTime.seconds) | \(time)")
        isSeeking = true
        avPlayer.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] completion in
            guard let self else { return }
            self.isSeeking = false
            self.ext.log("end player seeking \(completion) | \(self.currentTime)", error: self.avPlayer.error)
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
            guard let self, let duration = self.duration else { return }
            self.ext.log("boundary: \(self.currentTime) / \(duration) | playerStatus: \(self.status) | isPlaying: \(self.isPlaying)", logEnabled: self.timeLogEnabled)
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
            guard let self, let duration = self.duration else { return }
            self.ext.log("periodic: \(self.currentTime) / \(duration) | playerStatus: \(self.status) | isPlaying: \(self.isPlaying)", logEnabled: self.timeLogEnabled)
            guard self.isPlaying else { return }
            self.handleTime(.periodic(self.currentTime, duration))
        }
    }
    
    @objc
    func didPlayToEnd(_ noti: Notification) {
        guard let item = noti.object as? AVPlayerItem, item == playerItem else { return }
        ext.log("didPlayToEnd \(self)")
        // play to end, seek to start
        if item.duration.seconds > 0 {
            avPlayer.seek(to: .zero)
        }
        status = .playToEnd
    }
    @objc
    func failedToPlayToEnd(_ noti: Notification) {
        guard let item = noti.object as? AVPlayerItem, item == playerItem else { return }
        ext.log("failedToPlayToEnd")
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
            guard let self else { return }
            self.ext.log("player status: \(player.status)")
            switch player.status {
            case .failed: // AVPlayer 错误
                self.status = .failed(player.error ?? Ext.Error.inner("AVPlayer failed."))
            default: break
            }
        }))
        // timeControlStatus : 播放器时间控制状态
        playerObservers.append(avPlayer.observe(\.timeControlStatus, options: [.initial, .new], changeHandler: { [weak self] player, change in
            guard let self else { return }
            self.ext.log("player timeControlStatus: \(player.timeControlStatus) | currentTime: \(self.currentTime)")
            // 缓冲区域内容不够播放时，变为缓冲状态
            let isBuffering = player.timeControlStatus == .waitingToPlayAtSpecifiedRate && !(player.currentItem?.isPlaybackLikelyToKeepUp ?? false)
            self.bufferStatus = isBuffering ? .buffering : .bufferToReady
            switch player.timeControlStatus {
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
            guard let self else { return }
            self.ext.log("playerItem status: \(item.status)")
            switch item.status {
            case .readyToPlay:
                self.ext.log("playerItem readyToPlay.")
                self.bufferStatus = .bufferToReady
            case .failed: // AVPlayerItem 错误 (播放资源错误)
                self.status = .failed(item.error ?? Ext.Error.inner("player item failed."))
            default: break
            }
        }))
        // isPlaybackBufferEmpty : 当前缓冲区去是否为空 [true: 缓冲区为空，不能播放 | false: 缓冲区不为空，可以播放]
        itemObservers.append(avPlayer.observe(\.currentItem?.isPlaybackBufferEmpty, options: [.new], changeHandler: { [weak self] player, change in
            guard let self, let isPlaybackBufferEmpty = player.currentItem?.isPlaybackBufferEmpty else { return }
            self.ext.log("isPlaybackBufferEmpty: \(isPlaybackBufferEmpty)")
            self.bufferStatus = .buffering
        }))
        // isPlaybackLikelyToKeepUp : 缓冲区内容是否可以播放
        itemObservers.append(avPlayer.observe(\.currentItem?.isPlaybackLikelyToKeepUp, options: [.new], changeHandler: { [weak self] player, change in
            guard let self, let isPlaybackLikelyToKeepUp = player.currentItem?.isPlaybackLikelyToKeepUp else { return }
            self.ext.log("isPlaybackLikelyToKeepUp: \(isPlaybackLikelyToKeepUp)")
            guard isPlaybackLikelyToKeepUp else { return }
            self.bufferStatus = .bufferToReady
        }))
        // loadedTimeRanges : 缓冲区加载的时间范围
        itemObservers.append(avPlayer.observe(\.currentItem?.loadedTimeRanges, options: [.new], changeHandler: { [weak self] player, change in
            guard let self, let bufferTimeRange = player.currentItem?.loadedTimeRanges.first?.timeRangeValue, let duration = self.duration else { return }
            // 缓冲到的时间
            let bufferTime = bufferTimeRange.start.seconds  + bufferTimeRange.duration.seconds
            self.ext.log("buffering: \(bufferTime) / \(duration) | \(player.currentItem?.loadedTimeRanges ?? [])", logEnabled: self.timeLogEnabled)
            self.handleTime(.buffer(bufferTime, duration))
        }))
        // isPlaybackBufferFull : 缓冲区是否完成
        itemObservers.append(avPlayer.observe(\.currentItem?.isPlaybackBufferFull, options: [.new], changeHandler: { [weak self] player, change in
            guard let self, let isPlaybackBufferFull = player.currentItem?.isPlaybackBufferFull else { return }
            self.ext.log("isPlaybackBufferFull: \(isPlaybackBufferFull)")
            guard isPlaybackBufferFull else { return }
            self.bufferStatus = .bufferToEnd
        }))
    }
}

// MARK: - Log

extension ExtPlayer {
    public override var description: String {
        var msg = super.description
        msg += " | status: \(status)"
        msg += " | bufferStatus: \(bufferStatus)"
        msg += " | avPlayer: \(avPlayer)"
        if let playerItem = playerItem { msg += " | playerItem: \(playerItem)" }
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
        msg += " | status: \(status)"
        msg += " | timeControlStatus: \(timeControlStatus)"
        msg += " | rate: \(rate)"
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
        if let url = asset.ext.url { msg += " | \(url.ext.log)" }
        msg += " | status \(status)"
        msg += " | duration \(duration.seconds)"
        msg += " | isPlaybackBufferEmpty: \(isPlaybackBufferEmpty)"
        msg += " | isPlaybackLikelyToKeepUp: \(isPlaybackLikelyToKeepUp)"
        msg += " | isPlaybackBufferFull: \(isPlaybackBufferFull)"
        if let error = error { msg += " | \(Ext.Tag.error): \(error)" }
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

private extension ExtWrapper where Base == URL {
    var log: String {
        let tag: Ext.Tag = base.isFileURL ? .file : .network
        let msg: String = base.isFileURL ? base.path.ext.removePrefix(Sandbox.path) : base.absoluteString
        return "{\(tag) - \(msg)}"
    }
}
