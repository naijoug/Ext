//
//  CircleProgressView.swift
//  Ext
//
//  Created by guojian on 2021/10/9.
//

import UIKit

/// 圆形进度条
open class CircleProgressView: ExtView {
    
    /// 进度槽颜色
    public var trackColor: UIColor = .lightGray {
        didSet {
            setNeedsDisplay()
        }
    }
    /// 进度条颜色
    public var progressColor: UIColor = .darkGray {
        didSet {
            setNeedsDisplay()
        }
    }
    /// 进度条宽度
    public var lineWidth: CGFloat = 2 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// 进度
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
                                radius: bounds.size.width/2 - lineWidth,
                                startAngle: -CGFloat.pi/2,
                                endAngle: CGFloat.pi*3/2,
                                clockwise: true)
        
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = trackColor.cgColor
        trackLayer.lineWidth = lineWidth
        trackLayer.path = path.cgPath
        layer.insertSublayer(trackLayer, at: 0)
        
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = progressColor.cgColor
        progressLayer.lineWidth = lineWidth
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
