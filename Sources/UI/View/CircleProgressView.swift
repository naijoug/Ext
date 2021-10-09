//
//  CircleProgressView.swift
//  Ext
//
//  Created by guojian on 2021/10/9.
//

import UIKit

/// 进度条配置
public struct ProgressConfig {
    /// 进度条宽度
    public var lineWidth: CGFloat = 2
    /// 进度槽颜色
    public var trackColor: UIColor = .lightGray
    /// 进度条颜色
    public var progressColor: UIColor = .darkGray
}

/// 圆形进度条
open class CircleProgressView: ExtView {
    
    /// 进度条配置
    public var config: ProgressConfig = ProgressConfig()
    
    /// 进度 [0 ~ 1.0]
    public private(set) var progress: CGFloat = 0.0 {
        didSet {
            if progress < 0 {
                progress = 0
            } else if progress > 1.0 {
                progress = 1.0
            }
        }
    }
    
    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    
    open override func draw(_ rect: CGRect) {
        
        let path = UIBezierPath(arcCenter: CGPoint(x: bounds.midX, y: bounds.midY),
                                radius: bounds.size.width/2 - config.lineWidth,
                                startAngle: -CGFloat.pi/2,
                                endAngle: CGFloat.pi*3/2,
                                clockwise: true)
        
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = config.trackColor.cgColor
        trackLayer.lineWidth = config.lineWidth
        trackLayer.path = path.cgPath
        layer.insertSublayer(trackLayer, at: 0)
        
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = config.progressColor.cgColor
        progressLayer.lineWidth = config.lineWidth
        progressLayer.path = path.cgPath
        progressLayer.strokeStart = 0
        progressLayer.strokeEnd = CGFloat(progress)
        layer.insertSublayer(progressLayer, at: 1)
    }
    
    public func setProgress(_ progress: CGFloat, animation: Bool = false, duration: TimeInterval = 0.5) {
        CATransaction.begin()
        CATransaction.setDisableActions(!animation)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
        CATransaction.setAnimationDuration(duration)
        progressLayer.strokeEnd = progress
        CATransaction.commit()
    }
    
}
