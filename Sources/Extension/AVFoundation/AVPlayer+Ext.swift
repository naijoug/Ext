//
//  AVPlayer+Ext.swift
//  Ext
//
//  Created by guojian on 2021/6/11.
//

import AVFoundation

public extension ExtWrapper where Base == AVPlayer {

    /// 是否正在播放视频
    var isPlaying: Bool { base.timeControlStatus == .playing }
    
}
