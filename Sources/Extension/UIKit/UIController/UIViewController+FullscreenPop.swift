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

public extension ExtWrapper where Base: UIViewController {
    
    /// 启动全屏 pop
    static func fullscreenPop() {
        UIViewController.fullscreenPop()
        UINavigationController.fullscreenPopNavigation()
    }
    
}

public extension UIViewController {
    private static var isInteractivePopDisabledKey: UInt8 = 0
    /// pop 手势不可用
    var isInteractivePopDisabled: Bool {
        get { ext.getAssociatedObject(&Self.isInteractivePopDisabledKey, valueType: Bool.self) ?? false }
        set { ext.setAssociatedObject(&Self.isInteractivePopDisabledKey, value: newValue, policy: .retainNonatomic) }
    }
}

public extension UINavigationController {
    private static var fullscreenPopGestureRecognizerKey: UInt8 = 0
    /// 全屏 pop 手势
    var fullscreenPopGestureRecognizer: UIPanGestureRecognizer {
        guard let pan = ext.getAssociatedObject(&Self.fullscreenPopGestureRecognizerKey, valueType: UIPanGestureRecognizer.self) else {
            let pan = UIPanGestureRecognizer()
            pan.maximumNumberOfTouches = 1
            ext.setAssociatedObject(&Self.fullscreenPopGestureRecognizerKey, value: pan, policy: .retainNonatomic)
            return pan
        }
        return pan
    }
}

// MARK: - Swizzling Method

private extension UINavigationController {
    static func fullscreenPopNavigation() {
        ext.swizzlingInstanceMethod(self, original: #selector(pushViewController(_:animated:)), swizzled: #selector(fullscreenPop_pushViewController(_:animated:)))
    }
    
    @objc
    func fullscreenPop_pushViewController(_ viewController: UIViewController, animated: Bool) {
        if !(interactivePopGestureRecognizer?.view?.gestureRecognizers?.contains(fullscreenPopGestureRecognizer) ?? false) {
            interactivePopGestureRecognizer?.view?.addGestureRecognizer(fullscreenPopGestureRecognizer)
            
            let internalTargets = (interactivePopGestureRecognizer?.value(forKey: "targets") as? [NSObject]) ?? []
            Ext.debug("internalTargets: \(internalTargets) | \(interactivePopGestureRecognizer?.value(forKey: "targets"))")
            if let internalTarget = internalTargets.first?.value(forKey: "target") {
                let internalAction: Selector = NSSelectorFromString("handleNavigationTransition:")
                Ext.debug("target: \(internalTarget) | action: \(internalAction)")
                fullscreenPopGestureRecognizer.delegate = self.popGestueRecognizerDelegate
                fullscreenPopGestureRecognizer.addTarget(internalTarget, action: internalAction)
            }
            
            interactivePopGestureRecognizer?.isEnabled = false
        }
        
        navigationBarAppearance(viewController)
        
        Ext.debug("controller: \(viewController)")
        guard !viewControllers.contains(viewController) else { return }
        Ext.debug("push \(viewController)")
        fullscreenPop_pushViewController(viewController, animated: animated)
    }
    
    private func navigationBarAppearance(_ viewController: UIViewController) {
        guard appearanceEnabled else { return }
        
        viewController.viewWillAppearHandler = { [weak self] (controller, animated) in
            guard let `self` = self else { return }
            self.setNavigationBarHidden(controller.isPrefersNavigationBarHidden, animated: animated)
        }
        viewControllers.last?.viewWillAppearHandler = { [weak self] (controller, animated) in
            guard let `self` = self else { return }
            self.setNavigationBarHidden(controller.isPrefersNavigationBarHidden, animated: animated)
        }
    }
}

private extension UIViewController {
    
    static func fullscreenPop() {
        ext.swizzlingInstanceMethod(self, original: #selector(viewWillAppear(_:)), swizzled: #selector(fullscreenPop_viewWillAppear(_:)))
        ext.swizzlingInstanceMethod(self, original: #selector(viewWillDisappear(_:)), swizzled: #selector(fullscreenPop_viewWillDisappear(_:)))
    }
    
    @objc
    func fullscreenPop_viewWillAppear(_ animated: Bool) {
        fullscreenPop_viewWillAppear(animated)
        Ext.debug("full screen pop appear")
        
        viewWillAppearHandler?(self, animated)
    }
    @objc
    func fullscreenPop_viewWillDisappear(_ animated: Bool) {
        fullscreenPop_viewWillDisappear(animated)
        Ext.debug("full screen pop disappear")
        
        DispatchQueue.main.ext.after(delay: 0) {
            guard let controller = self.navigationController?.viewControllers.last,
                  !controller.isPrefersNavigationBarHidden else { return }
            self.navigationController?.setNavigationBarHidden(false, animated: false)
        }
    }
}

// MARK: - Associated Object

private extension UIViewController {
    
    typealias ViewWillAppearHandler = (UIViewController, Bool) -> Void
    private static var viewWillAppearHandlerKey: UInt8 = 0
    /// 视图将要出现
    var viewWillAppearHandler: ViewWillAppearHandler? {
        get { ext.getAssociatedObject(&Self.viewWillAppearHandlerKey, valueType: ViewWillAppearHandler.self) }
        set { ext.setAssociatedObject(&Self.viewWillAppearHandlerKey, value: newValue, policy: .retainNonatomic) }
    }
    
    private static var isPrefersNavigationBarHiddenKey: UInt8 = 0
    /// 是否导航栏隐藏
    var isPrefersNavigationBarHidden: Bool {
        get { ext.getAssociatedObject(&Self.isPrefersNavigationBarHiddenKey, valueType: Bool.self) ?? false }
        set { ext.setAssociatedObject(&Self.isPrefersNavigationBarHiddenKey, value: newValue, policy: .retainNonatomic) }
    }
    
    private static var interactivePopMaxAllowedInitalDistanceToLeftEdgeKey: UInt8 = 0
    /// pop 手势允许的距离屏幕左边最大距离
    var interactivePopMaxAllowedInitalDistanceToLefeEdge: CGFloat {
        get { ext.getAssociatedObject(&Self.interactivePopMaxAllowedInitalDistanceToLeftEdgeKey, valueType: CGFloat.self) ?? 0 }
        set { ext.setAssociatedObject(&Self.interactivePopMaxAllowedInitalDistanceToLeftEdgeKey, value: newValue, policy: .retainNonatomic) }
    }
}

private extension UINavigationController {
    var isTransitioning: Bool { (value(forKey: "_isTransitioning") as? Bool) ?? false }
    
    private static var popGestureRecognizerDelegateKey: UInt8 = 0
    /// pop 手势代理
    var popGestueRecognizerDelegate: FullscreenPopGestureRecognizerDelegate {
        guard let delegate = ext.getAssociatedObject(&Self.popGestureRecognizerDelegateKey, valueType: FullscreenPopGestureRecognizerDelegate.self) else {
            let delegate = FullscreenPopGestureRecognizerDelegate()
            delegate.navigationController = self
            ext.setAssociatedObject(&Self.popGestureRecognizerDelegateKey, value: delegate, policy: .retainNonatomic)
            return delegate
        }
        return delegate
    }
    
    private static var appearanceEnabledKey: UInt8 = 0
    var appearanceEnabled: Bool {
        get { ext.getAssociatedObject(&Self.appearanceEnabledKey, valueType: Bool.self) ?? false }
        set { ext.setAssociatedObject(&Self.appearanceEnabledKey, value: newValue, policy: .retainNonatomic) }
    }
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
        let maxAllowedInitalDistance = topController.interactivePopMaxAllowedInitalDistanceToLefeEdge
        if maxAllowedInitalDistance > 0 && beginningLocation.x > maxAllowedInitalDistance {
            return false
        }
        guard !navigationController.isTransitioning else { return false }
        
        let translation = pan.translation(in: pan.view)
        let multiplier: CGFloat = UIApplication.shared.ext.isRTL ? -1 : 1
        
        return translation.x * multiplier > 0
    }
    
}
