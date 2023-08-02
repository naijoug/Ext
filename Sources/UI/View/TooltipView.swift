//
//  TooltipView.swift
//  Ext
//
//  Created by guojian on 2023/8/2.
//

import UIKit

/// tooltip 视图
open class TooltipView: ExtView, ExtLogable {
    public var logLevel: Ext.LogLevel = .off
    
    /// tooltip 箭头方向
    public enum ArrowDirection: Int {
        case top
        case bottom
    }
    /// 箭头方向
    open var direction: ArrowDirection = .top
    /// 箭头位置 [0.0, 1.0]
    open var position: CGFloat = 0.5
    
    /// 目标视图 frame
    open var targetFrame: CGRect?
    
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView  = super.hitTest(point, with: event) else {
            ext.log("\(point) | targetFrame: \(targetFrame ?? .zero)")
            guard let targetFrame = targetFrame, targetFrame.contains(point) else {
                ext.log("hit other frame.")
                hide()
                return nil
            }
            ext.log("hit target frame.")
            hide()
            return nil
        }
        //ext.log("hitView : \(hitView)")
        return hitView
    }
    open override func layoutSubviews() {
        super.layoutSubviews()
        // ext.log("\(frame) | \(position)")
        var arrow = BubbleArrow()
        switch direction {
        case .top: arrow.direction = .top
        case .bottom: arrow.direction = .bottom
        }
        arrow.position = position
        layer.ext.bubble(arrow, in: bounds.size)
    }
    
    /// 隐藏视图
    public func hide() {
        removeFromSuperview()
    }
}
