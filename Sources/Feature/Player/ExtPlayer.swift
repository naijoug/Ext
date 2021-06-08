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
        
        /**
         Reference:
            - https://stackoverflow.com/questions/38867190/how-can-i-check-if-my-avplayer-is-buffering
         */
        
        case unknown                // 位置状态 (还未加载任何播放资源)
        case buffering              // 缓冲中
        case readyToPlay            // 准备好播放
        case playing                // 正在播放
        case paused                 // 暂停播放
        case playToEnd              // 播放完成
        case failed(_ error: Error) // 播放失败
        
        /// 是否可以进行缓冲
        public var isBufferable: Bool {
            switch self {
            case .readyToPlay: return false
            default: return true
            }
        }
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
        NotificationCenter.default.removeObserver(self)
    }
    /// 清理
    private func clear() {
        /// 状态清理
        isPlaying = false
        isSeeking = false
        status = .unknown
        /// 资源清理
        removeBoundaryObserver()
        removePeriodicObserver()
        avPlayer?.pause()
        avPlayer?.cancelPendingPrerolls()
        avPlayer?.replaceCurrentItem(with: nil)
        avPlayer = nil
        playerItem?.asset.cancelLoading()
        playerItem?.cancelPendingSeeks()
        playerItem = nil
    }
    
// MARK: - Player
    
    private var playerUrl: URL?
    private var playerItem: AVPlayerItem? {
        willSet {
            removePlayerItemObservers()
            removePlayerItemNotifations()
        }
        didSet {
            addPlayerItemObservers()
            addPlayerItemNotifications()
        }
    }
    /// AVPlayer
    private(set) var avPlayer: AVPlayer? {
        willSet {
            removePlayerObservers()
        }
        didSet {
            addPlayerObservers()
        }
    }
    private var boundaryObserver: Any?  // 边界监听
    private var periodicObserver: Any?  // 周期监听
}

//MARK: - Public

extension ExtPlayer {
    
    /// 设置播放资源
    func setPlayer(_ url: URL?) {
        guard let url = url else { return }
        clear()
        playerUrl = url
        
        let keys = ["tracks", "playable"]
        playerItem = AVPlayerItem(asset: AVURLAsset(url: url), automaticallyLoadedAssetKeys: keys)
        
        avPlayer = AVPlayer(playerItem: playerItem)
    }
    
    /// 当前播放时间
    public var currentTime: TimeInterval? { avPlayer?.currentTime().seconds }
    /// 当前播放资源总时长
    public var duration: TimeInterval? {
        guard let time = avPlayer?.currentItem?.duration.seconds else { return nil }
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
        guard let _ = playerUrl else { return }
        avPlayer?.play()
    }
    
    /// 暂停
    open func pause() {
        guard status != .paused else { return }
        avPlayer?.pause()
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
        removeBoundaryObserver()
        /// 时间点监听
        guard let times = boundaryTimes, times.count > 0 else { return }
        boundaryObserver = avPlayer?.addBoundaryTimeObserver(forTimes: times, queue: DispatchQueue.main) { [weak self] in
            guard let `self` = self else { return }
            guard let currentTime = self.currentTime, let duration = self.duration else { return }
            Ext.debug("boundary:  --- \(self) | \(currentTime) / \(duration)", logEnabled: self.logEnabled)
            self.delegate?.extPlayer(self, timeStatus: .boundary(currentTime, duration))
        }
    }
    func removeBoundaryObserver() {
        guard let observer = boundaryObserver else { return }
        avPlayer?.removeTimeObserver(observer)
        boundaryObserver = nil
    }
    /// 添加周期监听
    func addPeriodicObserver() {
        // 先移除
        removePeriodicObserver()
        // 添加周期监听
        guard let time = periodicTime, time > 0 else { return }
        periodicObserver = avPlayer?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(time, preferredTimescale: 600), queue: DispatchQueue.main) { [weak self] time in
            guard let `self` = self else { return }
            guard let currentTime = self.currentTime, let duration = self.duration else { return }
            Ext.debug("periodic:  --- \(self) | \(currentTime) / \(duration)", logEnabled: self.logEnabled)
            self.delegate?.extPlayer(self, timeStatus: .periodic(currentTime, duration))
        }
    }
    func removePeriodicObserver() {
        guard let observer = periodicObserver else { return }
        avPlayer?.removeTimeObserver(observer)
        periodicObserver = nil
    }
    
    func addPlayerItemNotifications() {
        guard let item = playerItem else { return }
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidPlayToEnd(_:)),
                                               name: .AVPlayerItemDidPlayToEndTime, object: item)
    }
    func removePlayerItemNotifations() {
        guard let item = playerItem else { return }
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: item)
    }
    @objc
    func playerItemDidPlayToEnd(_ notification: Notification) {
        guard let item = notification.object as? AVPlayerItem, item == playerItem else { return }
        logStatus("playToEnd")
        status = .playToEnd
    }
}

// MARK: - KVO

private var ExtPlayerKVOContext = 1
private extension ExtPlayer {
    private func addPlayerObservers() {
        guard let player = avPlayer else { return }
        
        player.observe(\.status, options: [.new]) { (player, change) in
            
        }
        player.observe(\.timeControlStatus, options: [.new]) { (player, change) in
            
        }
        
        
        //player.addObserver(self, forKeyPath: #keyPath(AVPlayer.rate), options: [.new], context: &ExtPlayerKVOContext)
        player.addObserver(self, forKeyPath: #keyPath(AVPlayer.status), options: [.new], context: &ExtPlayerKVOContext)
        player.addObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus), options: [.new], context: &ExtPlayerKVOContext)
    }
    func removePlayerObservers() {
        guard let player = avPlayer else { return }
        //player.removeObserver(self, forKeyPath: #keyPath(AVPlayer.rate))
        player.removeObserver(self, forKeyPath: #keyPath(AVPlayer.status))
        player.removeObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus))
    }
    
    private func addPlayerItemObservers() {
        guard let item = playerItem else { return }
        // 播放资源状态
        item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.new], context: &ExtPlayerKVOContext)
        // 加载的缓冲时间段
        item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges), options: [.new], context: &ExtPlayerKVOContext)
        // isPlaybackBufferEmpty : 当前缓冲区去是否为空 [true: 缓冲区为空，不能播放 | false: 缓冲区不为空，可以播放]
        //item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackBufferEmpty), options: [.new], context: &MediaPlayerKVOContext)
        // isPlaybackLikelyToKeepUp : 缓冲区内容是否可以播放
        item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp), options: [.new], context: &ExtPlayerKVOContext)
        // isPlaybackBufferFull : 缓冲区是否完成
        //item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackBufferFull), options: [.new], context: &MediaPlayerKVOContext)
    }
    private func removePlayerItemObservers() {
        guard let item = playerItem else { return }
        item.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
        item.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges))
        //item.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackBufferEmpty))
        item.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp))
        //item.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackBufferFull))
    }
}
extension ExtPlayer {
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        //Ext.debug("[[[ begin context: \(String(describing: context)) | MediaPlayerKVOContext: \(MediaPlayerKVOContext) | \(self)")
        guard context == &ExtPlayerKVOContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        guard let nsObject = object as? NSObject else { return }
        
        let oldValue = change?[.oldKey]
        let newValue = change?[.newKey]
        
        func logKVO() {
            logStatus((keyPath ?? "") + " | \(String(describing: oldValue)) ---> \(String(describing: newValue)) | \(nsObject.description)")
        }
        logKVO()
        //if keyPath == #keyPath(AVPlayer.rate) {
        //    guard let rate = newValue as? Float else { return }
        //    Ext.debug("rate: \(rate) | \(player?.rate ?? 0)")
        //} else
        if nsObject == avPlayer {
            observerPlayer(keyPath)
        } else if nsObject == playerItem {
            observerPlayerItem(keyPath, newValue: newValue)
        }
        //Ext.debug("]]] end context: \(String(describing: context)) | MediaPlayerKVOContext: \(MediaPlayerKVOContext) | \(self) \n\n")
    }
    
    private func observerPlayer(_ keyPath: String?) {
        if keyPath == #keyPath(AVPlayer.status) {
            Ext.debug("AVPlayer.status: \(avPlayer?.status ?? .unknown)", logEnabled: logEnabled)
            switch avPlayer?.status {
            case .failed: // AVPlayer 错误
                delegate?.extPlayer(self, status: .failed(avPlayer?.error ?? Ext.Error.inner("AVPlayer failed.")))
            default: break
            }
        } else if keyPath == #keyPath(AVPlayer.timeControlStatus) {
            Ext.debug("AVPlayer.timeControlStatus: \(avPlayer?.timeControlStatus ?? .paused)", logEnabled: logEnabled)
            switch avPlayer?.timeControlStatus {
            case .playing:  status = .playing
            case .paused:   status = .paused
            case .waitingToPlayAtSpecifiedRate:
                // 缓冲区域内容不够播放时，变为缓冲状态
                guard !(playerItem?.isPlaybackLikelyToKeepUp ?? false) else { return }
                guard status.isBufferable else { return }
                status = .buffering
            default: break
            }
        }
    }
    private func observerPlayerItem(_ keyPath: String?, newValue: Any?) {
        if keyPath == #keyPath(AVPlayerItem.status) {
            Ext.debug("AVPlayerItem.status: \(playerItem?.status ?? .unknown)", logEnabled: logEnabled)
            switch playerItem?.status {
            case .readyToPlay:
                status = .readyToPlay
            case .failed: // AVPlayerItem 错误 (播放资源错误)
                delegate?.extPlayer(self, status: .failed(playerItem?.error ?? Ext.Error.inner("AVPlayerItem failed.")))
            default: break
            }
        }
        else if keyPath == #keyPath(AVPlayerItem.loadedTimeRanges) {
            guard let loadedTimeRanges = newValue as? [NSValue] else { return }
            Ext.debug("loadedTimeRanges: \(loadedTimeRanges) | \(avPlayer?.currentItem?.loadedTimeRanges ?? [])", logEnabled: logEnabled)
            guard let bufferTimeRange = loadedTimeRanges.first?.timeRangeValue else { return }
            // 缓冲到的时间
            let bufferTime = bufferTimeRange.start.seconds  + bufferTimeRange.duration.seconds
            guard let duration = self.duration else { return }
            self.delegate?.extPlayer(self, timeStatus: .buffer(bufferTime, duration))
        }
        else if keyPath == #keyPath(AVPlayerItem.isPlaybackBufferEmpty) {
            guard let isPlaybackBufferEmpty = newValue as? Bool, isPlaybackBufferEmpty else { return }
            Ext.debug("isPlaybackBufferEmpty: \(isPlaybackBufferEmpty) | \(playerItem?.isPlaybackBufferEmpty ?? false)", logEnabled: logEnabled)
        }
        else if keyPath == #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp) {
            guard let isPlaybackLikelyToKeepUp = newValue as? Bool, isPlaybackLikelyToKeepUp else { return }
            Ext.debug("isPlaybackLikelyToKeepUp: \(isPlaybackLikelyToKeepUp) | \(playerItem?.isPlaybackLikelyToKeepUp ?? false)", logEnabled: logEnabled)
        }
        else if keyPath == #keyPath(AVPlayerItem.isPlaybackBufferFull) {
            guard let isPlaybackBufferFull = newValue as? Bool, isPlaybackBufferFull else { return }
            Ext.debug("isPlaybackBufferFull: \(isPlaybackBufferFull) | \(playerItem?.isPlaybackBufferFull ?? false)", logEnabled: logEnabled)
        }
    }
    
    func logStatus(_ title: String?) {
        guard let title = title, logEnabled else { return }
        Ext.debug(">>>title: \(title)")
        Ext.debug("\t\(avPlayer?.description ?? "")")
        Ext.debug("\t\(playerItem?.description ?? "")")
        Ext.debug("\n\n")
    }
}

// MARK: -

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
