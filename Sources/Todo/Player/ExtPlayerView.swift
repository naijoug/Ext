//
//  ExtPlayerView.swift
//  Ext
//
//  Created by naijoug on 2020/11/5.
//

import UIKit
import AVFoundation

/// Apple PlayerView
public class ApplePlayerView: UIView {
    public override class var layerClass: AnyClass { return AVPlayerLayer.self }
    public var playerLayer: AVPlayerLayer { return layer as! AVPlayerLayer }
    public var avPlayer: AVPlayer? {
        get { return playerLayer.player }
        set { playerLayer.player = newValue }
    }
}


extension ExtPlayerView: ExtPlayerDelegate {
    public func extPlayer(_ player: ExtPlayer, status: ExtPlayer.Status) {
        Ext.debug("status: \(status) | isPlaying: \(isPlaying) | \(urlString ?? "")", logEnabled: logEnabled)
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

public protocol ExtPlayerViewDelegate: class {
    func extPlayerView(_ playerView: ExtPlayerView, status: ExtPlayer.Status)
    func extPlayerView(_ playerView: ExtPlayerView, timeStatus: ExtPlayer.TimeStatus)
    
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
    public var logEnabled: Bool = false
    
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
    
    private var playerView: ApplePlayerView!
    
    private lazy var indicatorView: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView(style: .whiteLarge)
        self.addSubview(indicatorView)
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            indicatorView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            indicatorView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
        return indicatorView
    }()
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        playerView  = ext.add(ApplePlayerView())
        
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: self.topAnchor),
            playerView.leftAnchor.constraint(equalTo: self.leftAnchor),
            playerView.rightAnchor.constraint(equalTo: self.rightAnchor),
            playerView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
    
}

// MARK: - Public

public extension ExtPlayerView {
    
    /// 开始播放
    func play(_ time: Double? = nil) {
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
    func pause(_ time: Double? = nil) {
        Ext.debug("")
        isPlaying = false
        extPlayer.pause()
        guard let time = time else { return }
        extPlayer.seekTime(time)
    }
}
