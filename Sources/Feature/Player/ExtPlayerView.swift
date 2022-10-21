//
//  ExtPlayerView.swift
//  Ext
//
//  Created by naijoug on 2020/11/5.
//

import UIKit
import AVFoundation

/**
 Apple PlayerView
 
 Reference: https://developer.apple.com/documentation/avfoundation/avplayerlayer
 */
public class ApplePlayerView: UIView {
    public override class var layerClass: AnyClass { AVPlayerLayer.self }
    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    public var avPlayer: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }
    
    public enum VideoGravity {
        /// 等比拉伸显示全部内容(可能会出现黑边)
        case aspectFit
        /// 等比填充可视区域(超出部分会被截掉)
        case aspectFill
        /// 非等比填充可视区域(可能会出现变形)
        case resize
    }
    
    /// 视频显示模式
    public var videoGravity: VideoGravity = .aspectFit {
        didSet {
            switch videoGravity {
            case .aspectFit:
                playerLayer.videoGravity = .resizeAspect
            case .aspectFill:
                playerLayer.videoGravity = .resizeAspectFill
            case .resize:
                playerLayer.videoGravity = .resize
            }
        }
    }
}

public protocol ExtPlayerViewDelegate: AnyObject {
    func extPlayerView(_ playerView: ExtPlayerView, status: ExtPlayerView.Status)
    func extPlayerView(_ playerView: ExtPlayerView, didAction action: ExtPlayerView.Action)
}

open class ExtPlayerView: UIView {
    /// 播放器视图状态
    public enum Status: Equatable {
        case unknown                        // 未知状态
        case buffering                      // 正在缓冲
        case readyToPlay                    // 准备好播放
        case playing(time: TimeInterval, duration: TimeInterval) // 播放中
        case paused                         // 暂停播放
        case playToEnd                      // 播放结束
    }
    /// 播放器视图交互
    public enum Action {
        case tap
        case control(_ isPlaying: Bool)
    }
    public weak var delegate: ExtPlayerViewDelegate?
    
// MARK: - Params
    
    /// 资源路径字符串
    public var urlString: String? {
        didSet {
            guard let urlString = urlString, let url = URL(string: urlString) else { return }
            self.url = url
        }
    }
    /// 资源路径 URL
    public var url: URL? {
        didSet {
            guard let url = url else { return }
            extPlayer.playerUrl = url
            extPlayer.periodicTime = 2.0
            extPlayer.boundaryTimes = [NSValue(time: CMTime.init(value: 1, timescale: 1))]
            playerView.avPlayer = extPlayer.avPlayer
        }
    }
    
    public var videoGravity: ApplePlayerView.VideoGravity = .aspectFill {
        didSet {
            guard oldValue != videoGravity else { return }
            Ext.debug("\(oldValue) -> \(videoGravity)")
            playerView.videoGravity = videoGravity
        }
    }
    
    /// 是否静音🔇
    public var isMuted: Bool = false {
        didSet {
            extPlayer.isMuted = isMuted
        }
    }
    
// MARK: - Status
    
    /// 是否打印日志
    public var logEnabled: Bool = true
    
    /// 是否正在播放
    public var isPlaying = false
    
    /// 是否正在缓冲
    private var isBuffering: Bool = false {
        didSet {
            Ext.debug("\(isBuffering)")
            if isBuffering {
                indicatorView.startAnimating()
            } else {
                indicatorView.stopAnimating()
            }
        }
    }
    
    public private(set) var status: ExtPlayerView.Status = .unknown {
        didSet {
            guard oldValue != status else { return }
            Ext.debug("\(oldValue) -> \(status)", logEnabled: logEnabled)
            delegate?.extPlayerView(self, status: status)
        }
    }
    
// MARK: - UII
    
    private var clearPlayer: Bool = false
    private lazy var extPlayer: ExtPlayer = {
        let extPlayer = ExtPlayer()
        extPlayer.delegate = self
        self.clearPlayer = true
        return extPlayer
    }()
    
    private lazy var playerView: ApplePlayerView = {
        let playerView = ext.add(ApplePlayerView())
        playerView.ext.constraintToEdges(self)
        return playerView
    }()
    
    private lazy var indicatorView: UIActivityIndicatorView = {
        let indicatorView = ext.add(UIActivityIndicatorView(style: .whiteLarge))
        indicatorView.ext.constraintToCenter(self)
        return indicatorView
    }()
    
    deinit {
        clear()
    }
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        playerView.ext.active()
    }
    required public init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

public extension ExtPlayerView {
    /// 播放资源总时长
    var duration: TimeInterval? { extPlayer.duration }
    /// 当前播放时间
    var currentTime: TimeInterval? { extPlayer.currentTime }
}

extension ExtPlayerView: ExtPlayerDelegate {
    public func extPlayer(_ player: ExtPlayer, status: ExtPlayer.Status) {
        isPlaying = player.isPlaying
        
        switch status {
        case .paused:
            self.status = .paused
        case .playToEnd:
            self.status = .playToEnd
        default: ()
        }
    }
    public func extPlayer(_ player: ExtPlayer, bufferStatus status: ExtPlayer.BufferStatus) {
        isBuffering = status == .buffering
        switch status {
        case .buffering:
            self.status = .buffering
        default: ()
        }
    }
    public func extPlayer(_ player: ExtPlayer, timeStatus status: ExtPlayer.TimeStatus) {
        switch status {
        case .periodic(let time, let duration):
            self.status = .playing(time: time, duration: duration)
        case .boundary(let time, let duration):
            self.status = .playing(time: time, duration: duration)
        default: ()
        }
    }
}

// MARK: - Public

public extension ExtPlayerView {
    
    func clear() {
        if clearPlayer { extPlayer.clear() }
    }
    
    /// 开始播放
    func play() {
        guard extPlayer.playEnabled else { return }
        Ext.debug("")
        isPlaying = true
        extPlayer.play()
    }
    /// 暂停播放
    func pause() {
        Ext.debug("")
        isPlaying = false
        extPlayer.pause()
    }
    
    /// 调整播放时间
    func seek(_ time: TimeInterval, handler: Ext.ResultVoidHandler?) {
        extPlayer.seek(time, handler: handler)
    }
}

extension ExtPlayerView.Status: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown:                          return "unknown"
        case .buffering:                        return "buffering"
        case .readyToPlay:                      return "readyToPlay"
        case .playing(let time, let duration):  return "playing \(time) / \(duration)"
        case .paused:                           return "paused"
        case .playToEnd:                        return "playToEnd"
        }
    }
}
