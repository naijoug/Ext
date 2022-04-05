//
//  UINavigationController+FullscreenPop.swift
//  Ext
//
//  Created by naijoug on 2022/3/24.
//

import UIKit

/**
 Reference:
    - https://github.com/forkingdog/FDFullscreenPopGesture
 */

public extension ExtWrapper where Base: UINavigationController {
    
    /// 启动全屏 pop
    static func fullscreenPop() {
        UIViewController.fullscreenPop()
    }
    
}



public extension UIViewController {
    
}

// MARK: - Swizzling Method

private extension UIViewController {
    
    static func fullscreenPop() {
        ext.swizzlingInstanceMethod(self, original: #selector(viewWillAppear(_:)), swizzled: #selector(fullscreenPop_viewWillAppear(_:)))
    }
    
    @objc
    func fullscreenPop_viewWillAppear(_ animated: Bool) {
        fullscreenPop_viewWillAppear(animated)
        Ext.debug("full screen pop")
    }
    
}

// MARK: - Associated Object

private extension UIViewController {
    private static var isInteractivePopDisabledKey: UInt8 = 0
    var isInteractivePopDisabled: Bool {
        get {
            ext.getAssociatedObject(&Self.isInteractivePopDisabledKey, valueType: Bool.self) ?? false
        }
        set {
            ext.setAssociatedObject(&Self.isInteractivePopDisabledKey, value: newValue, policy: .assign)
        }
    }
    
    private static var isPrefersNavigationBarHidden: UInt8 = 0
    var isPrefersNavigationBarHidden: Bool {
        get {
            ext.getAssociatedObject(&Self.isPrefersNavigationBarHidden, valueType: Bool.self) ?? false
        }
        set {
            ext.setAssociatedObject(&Self.isPrefersNavigationBarHidden, value: newValue, policy: .assign)
        }
    }
}

private extension UINavigationController {
    private static var fullscreenPopGestureRecognizerKey: UInt8 = 0
    /// 全屏 pop 手势
    var fullscreenPopGestureRecognizer: UIPanDirectionGestureRecognizer {
        guard let pan = ext.getAssociatedObject(&Self.fullscreenPopGestureRecognizerKey, valueType: UIPanDirectionGestureRecognizer.self) else {
            let pan = UIPanDirectionGestureRecognizer()
            pan.maximumNumberOfTouches = 1
            ext.setAssociatedObject(&Self.fullscreenPopGestureRecognizerKey, value: pan, policy: .retainNonatomic)
            return pan
        }
        return pan
    }
    
    private static var popGestureRecognizerDelegateKey: UInt8 = 0
    /// pop 手势代理
    var popGestueRecognizerDelegate: FullscreenPopGestureRecognizerDelegate {
        guard let delegate = ext.getAssociatedObject(&Self.popGestureRecognizerDelegateKey, valueType: FullscreenPopGestureRecognizerDelegate.self) else {
            let delegate = FullscreenPopGestureRecognizerDelegate()
            return delegate
        }
        return delegate
    }
}

private class FullscreenPopGestureRecognizerDelegate: NSObject {
    
    
    
}
