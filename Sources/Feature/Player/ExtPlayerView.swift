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


extension ExtPlayerView: ExtPlayerDelegate {
    public func extPlayer(_ player: ExtPlayer, status: ExtPlayer.Status) {
        isBuffering = status == .buffering
        
        delegate?.extPlayerView(self, status: status)
    }
    public func extPlayer(_ player: ExtPlayer, timeStatus status: ExtPlayer.TimeStatus) {
        delegate?.extPlayerView(self, timeStatus: status)
    }
    
    @objc
    public func extPlayer(_ player: ExtPlayer, playerFailed error: Error?) {
        Ext.debug("\(error.debugDescription)  | \(urlString ?? "")")
        isPlaying = false
    }
}

public protocol ExtPlayerViewDelegate: AnyObject {
    func extPlayerView(_ playerView: ExtPlayerView, status: ExtPlayer.Status)
    func extPlayerView(_ playerView: ExtPlayerView, timeStatus status: ExtPlayer.TimeStatus)
    
    func extPlayerView(_ playerView: ExtPlayerView, didAction action: ExtPlayerView.Action)
}

open class ExtPlayerView: UIView {
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
            extPlayer.setPlayer(url)
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
    
    private(set) lazy var extPlayer: ExtPlayer = {
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

// MARK: - Public

public extension ExtPlayerView {
    
    func clear() {
        extPlayer.clear()
    }
    
    /// 开始播放
    func play(_ time: TimeInterval? = nil) {
        Ext.debug("")
        isPlaying = true
        guard let time = time else {
            extPlayer.play()
            return
        }
        extPlayer.seekTime(time) { completion in
            guard completion else { return }
            self.extPlayer.play()
        }
    }
    /// 暂停播放
    func pause(_ time: TimeInterval? = nil) {
        Ext.debug("")
        isPlaying = false
        extPlayer.pause()
        guard let time = time else { return }
        extPlayer.seekTime(time)
    }
}
