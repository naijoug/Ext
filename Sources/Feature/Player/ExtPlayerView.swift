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
    
    private lazy var extPlayer: ExtPlayer = {
        let extPlayer = ExtPlayer()
        extPlayer.delegate = self
        return extPlayer
    }()
    
    private lazy var playerView: ApplePlayerView = {
        let playerView = ext.add(ApplePlayerView())
        playerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: self.topAnchor),
            playerView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            playerView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
        return playerView
    }()
    
    private lazy var indicatorView: UIActivityIndicatorView = {
        let indicatorView = ext.add(UIActivityIndicatorView(style: .whiteLarge))
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            indicatorView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            indicatorView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
        return indicatorView
    }()
    
    deinit {
        clear()
    }
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .black
        playerView.ext.active()
    }
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
        extPlayer.clear()
    }
    
    /// 开始播放
    func play() {
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
