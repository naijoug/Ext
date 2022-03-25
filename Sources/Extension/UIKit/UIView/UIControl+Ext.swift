//
//  UIControl+Ext.swift
//  Ext
//
//  Created by guojian on 2021/12/29.
//

import UIKit

/**
 Reference:
    - https://stackoverflow.com/questions/25919472/adding-a-closure-as-target-to-a-uibutton
    - https://getswifty.dev/adding-closures-to-buttons-in-swift/
    - https://github.com/hhru/HandlersKit
 */

private var ExtAllTargetsKey: Int = 110

private extension NSObject {
    var extAllTargets: NSMutableArray {
        var targets = objc_getAssociatedObject(self, &ExtAllTargetsKey) as? NSMutableArray
        if targets == nil {
            targets = NSMutableArray()
            objc_setAssociatedObject(self, &ExtAllTargetsKey, targets, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        return targets ?? NSMutableArray()
    }
}

public extension ExtWrapper where Base: UIControl {
    
    private class ControlTarget: NSObject {
        
        private let event: UIControl.Event
        private let handler: (_ sender: Any?) -> Void
        
        init(_ event: UIControl.Event, handler: @escaping (_ sender: Any?) -> Void) {
            self.event = event
            self.handler = handler
            
            super.init()
        }
        
        @objc
        func action(_ sender: Any?) {
            handler(sender)
        }
    }
        
    /// 添加事件处理者
    func addEventHandler(_ event: UIControl.Event, handler: @escaping (_ sender: Any?) -> Void) {
        let target = ControlTarget(event, handler: handler)
        base.addTarget(target, action: #selector(target.action(_:)), for: event)
        base.extAllTargets.add(target)
    }
    
    /// 点击事件处理
    func tap(_ handler: @escaping () -> Void) {
        addEventHandler(.touchUpInside) { _ in handler() }
    }
}

public extension ExtWrapper where Base: UIGestureRecognizer {
    
    private class GestureTarget: NSObject {
        private let handler: (_ sender: Any?) -> Void
        
        init(_ handler: @escaping (_ sender: Any?) -> Void) {
            self.handler = handler
            
            super.init()
        }
        
        @objc
        func action(_ sender: Any?) {
            handler(sender)
        }
    }
    
    func addHandler(_ handler: @escaping (_ sender: Any?) -> Void) {
        let target = GestureTarget(handler)
        base.addTarget(target, action: #selector(target.action(_:)))
        base.extAllTargets.add(target)
    }
    
}
