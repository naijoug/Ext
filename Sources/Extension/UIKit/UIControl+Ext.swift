//
//  UIControl+Ext.swift
//  Ext
//
//  Created by guojian on 2021/12/29.
//

import UIKit

private class ExtControlTarget: NSObject {
    
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

private var ExtControlTargetsKey: Int = 110

public extension ExtWrapper where Base: UIControl {
    
    private var allControlTargets: NSMutableArray {
        var targets = objc_getAssociatedObject(self, &ExtControlTargetsKey) as? NSMutableArray
        if targets == nil {
            targets = NSMutableArray()
            objc_setAssociatedObject(self, &ExtControlTargetsKey, targets, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        return targets ?? NSMutableArray()
    }
    
    func addHandler(_ event: UIControl.Event, handler: @escaping (_ sender: Any?) -> Void) {
        let target = ExtControlTarget(event, handler: handler)
        base.addTarget(target, action: #selector(target.action(_:)), for: event)
        
        allControlTargets.add(target)
    }
    
}
