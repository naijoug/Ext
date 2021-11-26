//
//  WaveformView.swift
//  Ext
//
//  Created by naijoug on 2020/6/16.
//

import UIKit

/**
 Reference:
    - https://github.com/kevinzhow/Waver
    - https://github.com/stefanceriu/SCSiriWaveformView
 
    三角函数公式：y = Asin（ωx+φ）+ C
    A：振幅，波纹在Y轴的高度，成正比，越大Y轴峰值越大。
    ω：和周期有关，越大周期越短。
    φ：横向偏移量，控制波纹的移动。
    C：整个波纹的Y轴偏移量。
 */

/// 波形视图
public class WaveformView: ExtView {
    
    /// 波纹条数
    private var numberOfWaves = 5
    /// 波纹线条
    private var waves = [CAShapeLayer]()
    
    /// 振幅
    private var amplitude: CGFloat = 0.0
    /// 闲置振幅
    private var idleAmplitude: CGFloat = 0.0
    /// 周期
    private var frequency: CGFloat = 3
    /// 密度
    private var density: CGFloat = 5
    /// 位移量
    private var phase: CGFloat = 0.0
    private var phaseShift: CGFloat = -0.25
    
    /// 定时器
    private var displayLink: CADisplayLink?
    
    public var level: CGFloat = 0 {
        didSet {
            // Ext.debug("level: \(level)")
            amplitude = max(level, idleAmplitude)
        }
    }
    
    public override func setupUI() {
        super.setupUI()
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        for i in 0..<numberOfWaves {
            let waveLine = CAShapeLayer()
            waveLine.lineCap    = .butt
            waveLine.lineJoin   = .round
            waveLine.lineWidth  = i == 0 ? 1.0 : 1.0
            waveLine.fillColor  = UIColor.clear.cgColor
            let progress = 1.0 - CGFloat(i)/CGFloat(numberOfWaves)
            let multiplier = min(1.0, (progress/3.0*2.0) + CGFloat(1.0/3.0))
            let color = UIColor.white.withAlphaComponent(i == 0 ? 1.0 : 1.0*multiplier*0.4)
            waveLine.strokeColor = color.cgColor
            layer.addSublayer(waveLine)
            waves.append(waveLine)
        }
    }
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        level = 0
        updateMeters()
    }
    deinit {
        stop()
        Ext.debug("", tag: .recycle)
    }
    
    public func start() {
        stop()
        displayLink = CADisplayLink(target: self, selector: #selector(WaveformView.updateMeters))
        displayLink?.add(to: .current, forMode: .common)
    }
  
    public func stop() {
        guard displayLink != nil else { return }
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc
    private func updateMeters() {
        UIGraphicsBeginImageContext(frame.size)
        
        let waveHeight      = bounds.height
        let waveWidth       = bounds.width
        let waveMid         = waveWidth / 2
        let maxAmplitude    = waveHeight / 3 // 波峰
        
        phase += phaseShift
        
        for i in 0..<waves.count {
            let path = UIBezierPath()
            let progress = 1.0 - CGFloat(i) / CGFloat(waves.count)
            let normedAmplitude = (1.5 * progress - 0.5) * amplitude
            
            var x: CGFloat = 0
            while x < waveWidth + density {
                let scaling: CGFloat = -pow(x / waveMid - 1, 2) + 1
                let y = scaling * maxAmplitude * normedAmplitude * sin(2 * CGFloat.pi * (x / waveWidth) * frequency + phase) + waveHeight/2
                if x == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                x += density
            }
            waves[i].path = path.cgPath
        }
        
        UIGraphicsEndImageContext()
    }
}
