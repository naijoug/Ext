//
//  AudioProgressView.swift
//  Ext
//
//  Created by naijoug on 2022/3/15.
//

import UIKit

/// 音波进度视图
public class AudioProgressView: ExtView {
    
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
    /// 进度
    public var progress: Float = 0.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    /// 音波数据
    public var items = [Int]() {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public override func setupUI() {
        super.setupUI()
        backgroundColor = .clear
    }
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let count = items.count
        let max = items.max() ?? 0
        guard count > 0, max > 0, rect.width > 0, rect.height > 0 else { return }
        
        let context = UIGraphicsGetCurrentContext()
        
        let itemW: CGFloat = rect.width / CGFloat(count)
        let itemH: CGFloat = rect.height
        let progressW = rect.width * CGFloat(progress)
        for i in 0..<count {
            let item = items[i]
            let isZero = item == 0
            let barH = isZero ? 0.5 : CGFloat(item)/CGFloat(max) * itemH
            let barW = itemW * (isZero ? 1 : 0.8)
            let barX = itemW * CGFloat(i) + (itemW - barW)/2
            let barY = (itemH - barH) / 2
            let barRect = CGRect(x: barX, y: barY, width: barW, height: barH)
            //Ext.log("bar rect: \(barRect) | \(count)")
            let color = barX > progressW ? trackColor : progressColor
            context?.setFillColor(color.cgColor)
            context?.addRect(barRect)
            context?.drawPath(using: .fill)
        }
    }
}
