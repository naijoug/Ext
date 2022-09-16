//
//  UIViewController+FullscreenPop.swift
//  Ext
//
//  Created by naijoug on 2022/5/18.
//

import UIKit

/**
 Reference:
    - https://github.com/forkingdog/FDFullscreenPopGesture
 */

extension ExtWrapper where Base: UINavigationController {
    /// 全屏 pop 功能
    static func fullscreenPop() {
        UINavigationController.fullscreenPop()
    }
    
    /// 全屏 pop 手势
    var fullscreenPopGestureRecognizer: UIPanGestureRecognizer {
        guard let pan = base.ext.getAssociatedObject(&Base.fullscreenPopGestureRecognizerKey, valueType: UIPanGestureRecognizer.self) else {
            let pan = UIPanGestureRecognizer()
            pan.maximumNumberOfTouches = 1
            base.ext.setAssociatedObject(&Base.fullscreenPopGestureRecognizerKey, value: pan, policy: .retainNonatomic)
            return pan
        }
        return pan
    }
}

public extension ExtWrapper where Base: UIViewController {
    
    var isInteractivePopDisabled: Bool { base.isInteractivePopDisabled }
    
    func interactionPopDisabled(_ disabled: Bool) {
        base.isInteractivePopDisabled = disabled
    }
    
}

// MARK: - Private

private extension UIViewController {
    private static var isInteractivePopDisabledKey: UInt8 = 0
    private static var interactivePopMaxDistanceToLeftEdgeKey: UInt8 = 0
    
    /// pop 手势不可用
    var isInteractivePopDisabled: Bool {
        get { ext.getAssociatedObject(&Self.isInteractivePopDisabledKey, valueType: Bool.self) ?? false }
        set { ext.setAssociatedObject(&Self.isInteractivePopDisabledKey, value: newValue, policy: .retainNonatomic) }
    }
    
    /// pop 手势允许的距离屏幕左边最大距离
    var interactivePopMaxDistanceToLefeEdge: CGFloat {
        get { ext.getAssociatedObject(&Self.interactivePopMaxDistanceToLeftEdgeKey, valueType: CGFloat.self) ?? 0 }
        set { ext.setAssociatedObject(&Self.interactivePopMaxDistanceToLeftEdgeKey, value: newValue, policy: .retainNonatomic) }
    }
}

private extension UINavigationController {
    static var fullscreenPopGestureRecognizerKey: UInt8 = 0
    static var popGestureRecognizerDelegateKey: UInt8 = 0
    
    static func fullscreenPop() {
        ext.swizzlingInstanceMethod(self, original: #selector(pushViewController(_:animated:)), swizzled: #selector(fullscreenPop_pushViewController(_:animated:)))
    }
    
    @objc
    func fullscreenPop_pushViewController(_ viewController: UIViewController, animated: Bool) {
        if !(interactivePopGestureRecognizer?.view?.gestureRecognizers?.contains(ext.fullscreenPopGestureRecognizer) ?? false) {
            interactivePopGestureRecognizer?.view?.addGestureRecognizer(ext.fullscreenPopGestureRecognizer)
            
            let internalTargets = (interactivePopGestureRecognizer?.value(forKey: "targets") as? [AnyObject]) ?? []
            //Ext.debug("internalTargets: \(internalTargets) | \(String(describing: interactivePopGestureRecognizer?.value(forKey: "targets")))")
            if let internalTarget = internalTargets.first?.value(forKey: "target") {
                let internalAction: Selector = NSSelectorFromString("handleNavigationTransition:")
                //Ext.debug("target: \(internalTarget) | action: \(internalAction)")
                ext.fullscreenPopGestureRecognizer.delegate = self.popGestueRecognizerDelegate
                ext.fullscreenPopGestureRecognizer.addTarget(internalTarget, action: internalAction)
            }
            
            interactivePopGestureRecognizer?.isEnabled = false
        }
        
        guard !viewControllers.contains(viewController) else { return }
        //Ext.debug("push \(viewController)", locationEnabled: false)
        fullscreenPop_pushViewController(viewController, animated: animated)
    }
    
    /// pop 手势代理
    private var popGestueRecognizerDelegate: FullscreenPopGestureRecognizerDelegate {
        guard let delegate = ext.getAssociatedObject(&Self.popGestureRecognizerDelegateKey, valueType: FullscreenPopGestureRecognizerDelegate.self) else {
            let delegate = FullscreenPopGestureRecognizerDelegate()
            delegate.navigationController = self
            ext.setAssociatedObject(&Self.popGestureRecognizerDelegateKey, value: delegate, policy: .retainNonatomic)
            return delegate
        }
        return delegate
    }
    
    var isTransitioning: Bool { (value(forKey: "_isTransitioning") as? Bool) ?? false }
}

// MARK: - Delegate

private class FullscreenPopGestureRecognizerDelegate: NSObject, UIGestureRecognizerDelegate {
    
    weak var navigationController: UINavigationController?
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
        guard let navigationController = navigationController,
              navigationController.viewControllers.count > 1,
              let topController = navigationController.viewControllers.last else { return false }
        guard !topController.isInteractivePopDisabled else { return false }
        
        let beginningLocation = gestureRecognizer.location(in: gestureRecognizer.view)
        let maxDistanceToLefeEdge = topController.interactivePopMaxDistanceToLefeEdge
        if maxDistanceToLefeEdge > 0 && beginningLocation.x > maxDistanceToLefeEdge { return false }
        guard !navigationController.isTransitioning else { return false }
        
        let translation = pan.translation(in: pan.view)
        let multiplier: CGFloat = UIApplication.shared.ext.isRTL ? -1 : 1
        
        return translation.x * multiplier > 0
    }
    
}
