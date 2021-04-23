//
//  UIPanDirectionGestureRecognizer.swift
//  Ext
//
//  Created by naijoug on 2020/5/27.
//

import UIKit.UIGestureRecognizerSubclass

/** Reference:
    - https://stackoverflow.com/questions/7100884/uipangesturerecognizer-only-vertical-or-horizontal
    - https://stackoverflow.com/questions/11777281/detecting-the-direction-of-pan-gesture-in-ios
 */

open class UIPanDirectionGestureRecognizer: UIPanGestureRecognizer {
    
    public enum Direction {
        case anywhere       // 任何方向
        case vertical       // 垂直方向
        case horizontal     // 水平方向
    }
    
    /// 平移手势方向
    public var direction : Direction = .anywhere
    
    /// 检测到移动手势
    public var movedHandler: (() -> Void)?
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
    
        guard state == .began else { return }
        movedHandler?()
        
        let vel = velocity(in: self.view!)
        switch direction {
        case .horizontal where abs(vel.y) > abs(vel.x):
            Ext.debug("vertical cancelled")
            state = .cancelled
        case .vertical where abs(vel.x) > abs(vel.y):
            Ext.debug("horizontal cancelled")
            state = .cancelled
        default:
            break
        }
    }
}
