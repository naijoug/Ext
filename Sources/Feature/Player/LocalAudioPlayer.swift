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
    
    /// 播放模式
    public enum Mode {
        case single(_ url: URL) // 单一播放模式
        case queue(_ urls: [URL]) // 队列播放模式
    }
    
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
    
    /// 播放模式
    private var mode: LocalAudioPlayer.Mode?
    /// 播放队列
    private var urlQueue = [URL]()
}
extension LocalAudioPlayer: AVAudioPlayerDelegate {
    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Ext.debug("audio 播放出错 \(error?.localizedDescription ?? "")")
        delegate?.audioPlayer(self, status: .failed(error))
    }
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Ext.debug("audio 播放完成 \(flag)")
        switch self.mode {
        case .single:
            self.delegate?.audioPlayer(self, status: .playEnd)
            self.stop()
        case .queue:
            self.playQueue()
        default: break
        }
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
    
//    /// 播放音频
//    func play(_ mode: LocalAudioPlayer.Mode) {
//        self.stop()
//        self.mode = mode
//        switch mode {
//        case .single(let url, let time):
//            self.play(url, at: time)
//        case .queue(let urls):
//            urlQueue = urls
//            self.playQueue()
//        }
//    }
    
    /// 设置音频播放模式
    func setup(_ mode: LocalAudioPlayer.Mode) {
        self.stop()
        self.mode = mode
        switch mode {
        case .single(let url):
            self.play(url)
        case .queue(let urls):
            urlQueue = urls
            self.playQueue()
        }
    }
    
    /// 播放队列中的音频
    private func playQueue() {
        guard !urlQueue.isEmpty else {
            Ext.debug("队列为空，全部播放完成.")
            self.delegate?.audioPlayer(self, status: .playEnd)
            self.stop()
            return
        }
        // 出队列进行播放
        let url = urlQueue.removeFirst()
        Ext.debug("出队列播放 url: \(url.path)")
        play(url)
    }
    
    /// 播放指定路径音频
    private func play(_ url: URL, at time: TimeInterval? = nil) {
        do {
            if avPlayer != nil {
                avPlayer?.stop()
                avPlayer = nil
            }
            
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            Ext.debug("play audio url: \(player.currentTime) -> \(time ?? 0) | device \(player.deviceCurrentTime) | \(url.path)")
            self.avPlayer = player
            play(time)
        } catch {
            Ext.debug("播放音频失败")
            delegate?.audioPlayer(self, status: .failed(error))
        }
    }
    
    /// 播放到指定时间
    func play(_ time: TimeInterval? = nil) {
        guard let player = avPlayer else { return }
        player.isMeteringEnabled = isMeteringEnabled
        player.currentTime = time ?? 0
        player.play()
        
        delegate?.audioPlayer(self, status: .playing)
        startTimer()
    }
    
    /// 暂停播放
    func pause() {
        stopTimer()
        avPlayer?.pause()
        
        delegate?.audioPlayer(self, status: .paused)
        Ext.debug("暂停播放")
    }
    
    /// 停止播放
    func stop() {
        mode = nil
        urlQueue.removeAll()
        
        stopTimer()
        avPlayer?.stop()
        avPlayer = nil
        Ext.debug("停止播放")
    }
}
