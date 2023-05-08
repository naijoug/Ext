//
//  GlobalPlayer.swift
//  Ext
//
//  Created by guojian on 2023/5/8.
//

import Foundation

public extension Notification.Name {
    /// 全局播放器🔇静音控制变化通知
    static let globalPlayerMuted = Notification.Name("globalPlayerMuted")
}

/// 全局播放器
public final class GlobalPlayer: ExtLogable {
    public var logLevel: Ext.LogLevel = .off
    
    public static let shared = GlobalPlayer()
    private init() {}
    
    /// 关联的播放视图
    private weak var playerView: UIView?
    /// 当前用于播放的播放器
    private weak var player: ExtPlayer? {
        didSet {
            ext.log("player changed: \n\t\(oldValue) \n\t---> \n\t\(player)")
            guard oldValue != player else { return }
            oldValue?.pause()
            
            player?.addTimeHandler({ [weak self] status in
                guard let self else { return }
                switch status {
                case .periodic, .boundary:
                    if let playerView = self.playerView, playerView.window == nil {
                        self.ext.log("播放器▶️离开视图还在播放, ⏸暂停播放")
                        self.player?.pause()
                    }
                default: ()
                }
            })
        }
    }
    
    /// 是否静音🔇
    public private(set) var isMuted: Bool = true
    
    /// 设置静音🔇状态
    /// - Parameter isMuted: 是否静音🔇
    public func mute(_ isMuted: Bool) {
        guard self.isMuted != isMuted else { return }
        self.isMuted = isMuted
        NotificationCenter.default.post(name: .globalPlayerMuted, object: nil, userInfo: ["muted": isMuted])
    }
    
    /// 切换静音🔇状态
    public func switchMuted() {
        mute(!isMuted)
    }
    
    /// 绑定当前正在播放器
    /// - Parameters:
    ///   - player: 播放器
    ///   - playerView: 播放器关联的 UI 视图
    public func bind(_ player: ExtPlayer?, playerView: UIView?) {
        self.player = player
        self.playerView = playerView
    }
    
    /// 暂停播放
    public func pause() {
        guard player?.isPlaying ?? false else { return }
        player?.pause()
    }
}
