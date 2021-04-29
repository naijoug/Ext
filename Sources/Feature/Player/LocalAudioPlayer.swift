//
//  LocalAudioPlayer.swift
//  Ext
//
//  Created by naijoug on 2021/4/23.
//

import Foundation
import AVFoundation

public protocol LocalAudioPlayerDelegate: AnyObject {
    func audioPlayer(_ player: LocalAudioPlayer, status: LocalAudioPlayer.Status)
    func audioPlayer(_ player: LocalAudioPlayer, timeStatus status: LocalAudioPlayer.TimeStatus)
}

/// 本地音频播放器
public class LocalAudioPlayer: NSObject {
    /// 播放状态
    public enum Status {
        case playing
        case paused
        case playEnd
        case failed(_ error: Error?)
    }
    /// 播放时间状态
    public enum TimeStatus {
        case level(_ level: CGFloat)
        case progress(_ currentTime: TimeInterval, duration: TimeInterval)
    }
    
    public weak var delegate: LocalAudioPlayerDelegate?
    /// 是否测量声音分贝信息
    public var isMeteringEnabled: Bool = false
    
// MARK: - Player
    
    public private(set) var avPlayer: AVAudioPlayer?
    /// 定时器
    private var timer: CADisplayLink?
    
    /// 播放资源 urls
    private var urls = [URL]()
    /// 正在播放资源的索引
    private var playIndex: Int = -1
}
extension LocalAudioPlayer: AVAudioPlayerDelegate {
    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Ext.debug("audio 播放出错 \(error?.localizedDescription ?? "")")
        delegate?.audioPlayer(self, status: .failed(error))
    }
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Ext.debug("audio 播放完成 \(flag)")
        
        stopTimer()
        avPlayer?.stop()
        avPlayer = nil
        
        guard playIndex == urls.count - 1 else {
            Ext.debug("播放下一个资源")
            self.play()
            return
        }
        playIndex = -1
        Ext.debug("全部播放完成.")
        self.delegate?.audioPlayer(self, status: .playEnd)
    }
}
private extension LocalAudioPlayer {
    func startTimer() {
        stopTimer()
        
        Ext.debug("start timer...")
        timer = CADisplayLink(target: self, selector: #selector(timerAction))
        timer?.add(to: .current, forMode: .common)
    }
    func stopTimer() {
        guard timer != nil else { return }
        
        timer?.invalidate()
        timer = nil
        Ext.debug("stop timer.")
    }
    @objc
    func timerAction() {
        guard let avPlayer = self.avPlayer else { return }
        //Ext.debug("currentTime: \(avPlayer.currentTime) | duration: \(avPlayer.duration)")
        delegate?.audioPlayer(self, timeStatus: .progress(avPlayer.currentTime, duration: avPlayer.duration))
        
        guard isMeteringEnabled else { return }
        avPlayer.updateMeters()
        let average = avPlayer.averagePower(forChannel: 0) // 均值分贝
        let db = CGFloat(pow(10, (0.06 * average))) // 分贝
        //Ext.debug("average: \(average) | db: \(db)")
        delegate?.audioPlayer(self, timeStatus: .level(db))
    }
}
public extension LocalAudioPlayer {
    
    /// 是否正在播放
    var isPlaying: Bool { avPlayer?.isPlaying ?? false }
    
    /// 设置播放资源 Url
    func setup(_ urls: [URL]) {
        self.clear()
        
        self.urls = urls
    }
    
    /// 播放到指定时间
    func play(_ time: TimeInterval? = nil) {
        if let player = avPlayer {
            if let time = time {
                player.currentTime = time
            }
            player.play()
            Ext.debug("play audio url: \(player.currentTime) -> \(time ?? 0) | device \(player.deviceCurrentTime)")
            
            delegate?.audioPlayer(self, status: .playing)
            startTimer()
            return
        }
        
        playIndex += 1
        
        guard 0 <= playIndex, playIndex < urls.count else { return }
        
        let url = urls[playIndex]
        Ext.debug("播放 \(playIndex) url: \(url.path)")
        playUrl(url)
    }
    
    /// 暂停播放
    func pause() {
        stopTimer()
        avPlayer?.pause()
        
        delegate?.audioPlayer(self, status: .paused)
        Ext.debug("暂停播放")
    }
    
    /// 清空播放器
    func clear() {
        urls.removeAll()
        playIndex = -1
        
        stopTimer()
        avPlayer?.stop()
        avPlayer = nil
        Ext.debug("停止播放，清空播放器")
    }
    
    /// 播放指定路径音频
    private func playUrl(_ url: URL, time: TimeInterval? = nil) {
        do {
            if avPlayer != nil {
                avPlayer?.stop()
                avPlayer = nil
            }
            
            let player = try AVAudioPlayer(contentsOf: url)
            self.avPlayer = player
            player.delegate = self
            player.isMeteringEnabled = isMeteringEnabled
            player.currentTime = time ?? 0
            player.play()
            Ext.debug("play audio url: \(player.currentTime) -> \(time ?? 0) | device \(player.deviceCurrentTime) | \(url.path)")
            
            delegate?.audioPlayer(self, status: .playing)
            startTimer()
        } catch {
            Ext.debug("播放音频失败")
            delegate?.audioPlayer(self, status: .failed(error))
        }
    }
}
