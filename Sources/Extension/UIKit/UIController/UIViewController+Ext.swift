//
//  UIViewController+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/28.
//

import UIKit

public extension Ext {
    /// 功能
    enum Feature {
        case lifecycle
        case unique
        case fullscreenPop
    }
    
    private static var features = [Feature]()
    /// 激活功能
    static func active(_ features: [Feature]) {
        Ext.features = features
        features.forEach { $0.active() }
    }
}
extension Ext.Feature {
    var isActive: Bool { Ext.features.contains(where: { $0 == self }) }
    
    fileprivate func active() {
        switch self {
        case .lifecycle:
            UIViewController.ext.lifecycle()
        case .unique:
            UIViewController.ext.unique()
        case .fullscreenPop:
            UINavigationController.ext.fullscreenPop()
        }
    }
}

// MARK: - Storyboard

public extension ExtWrapper where Base: UIViewController {
    
    /// 从指定 Storyboard 创建控制器
    ///
    /// - Parameter sbName: Storyboard 名称
    /// - Parameter bundle: Storyboard 所在 Bundle
    /// - Returns: 当前控制器类型实例
    static func instantiateFromStoryboard(sbName: String, bundle: Bundle? = nil) -> Base {
        func instanceFromStoryboard<T>(sbName: String) -> T where T: UIViewController {
            if let vc = UIStoryboard(name: sbName, bundle: bundle).instantiateViewController(withIdentifier: "\(Base.self)") as? T {
                return vc
            }
            fatalError("Load storyboard controller failure \(self)")
        }
        return instanceFromStoryboard(sbName: sbName)
    }
    
}

// MARK: -

private extension UIViewController {
    /// do nothing for lazy view controller active
    func active() { }
}

public extension ExtWrapper where Base: UIViewController {
    
    /// do nothing for lazy view controller active
    func active() {
        base.active()
    }
    
    /// 控制器视图是否加载
    var isViewLoaded: Bool { base.viewIfLoaded != nil }
    
    /// 控制器是否可见
    var isVisible: Bool {
        // Refrence: https://stackoverflow.com/questions/2777438/how-to-tell-if-uiviewcontrollers-view-is-visible
        base.viewIfLoaded?.window != nil
    }
    
    /// 导航栏返回按钮标题
    func backTitle(_ title: String = "") {
        base.navigationItem.backBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: nil, action: nil)
    }
    
    /// 是否使用导航栏大标题
    func largeTitle(_ enabled: Bool) {
        base.navigationController?.navigationBar.prefersLargeTitles = enabled
        base.navigationItem.largeTitleDisplayMode = enabled ? .always : .never
    }
}

public extension ExtWrapper where Base: UIViewController {
    /// 导航栏图片位置
    enum ImagePostion {
        case left
        case right
    }
    
    /// 设置 pop 关闭页面的导航栏 item 图片
    /// - Parameters:
    ///   - image: 图片
    ///   - position: 导航栏位置
    func setPopImage(_ image: UIImage?, position: ImagePostion = .left) {
        switch position {
        case .left:
            base.navigationItem.leftBarButtonItem = base.popBarButtonItem(image)
        case .right:
            base.navigationItem.rightBarButtonItem = base.popBarButtonItem(image)
        }
    }
    
    /// 设置 dismiss 关闭页面的导航栏 item 图片
    /// - Parameters:
    ///   - image: 图片
    ///   - postion: 导航栏位置
    func setDismissImage(_ image: UIImage?, position: ImagePostion = .left) {
        switch position {
        case .left:
            base.navigationItem.leftBarButtonItem = base.dismissBarButtonItem(image)
        case .right:
            base.navigationItem.rightBarButtonItem = base.dismissBarButtonItem(image)
        }
    }
}

private extension UIViewController {
    
    func popBarButtonItem(_ image: UIImage?) -> UIBarButtonItem {
        UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(extPopAction))
    }
    func dismissBarButtonItem(_ image: UIImage?) -> UIBarButtonItem {
        UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(extDismissAction))
    }
    
    @objc
    func extPopAction() {
        navigationController?.popViewController(animated: true)
    }
    @objc
    func extDismissAction() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Child Controller

public extension ExtWrapper where Base: UIViewController {
    
    // Reference: https://www.swiftbysundell.com/articles/using-child-view-controllers-as-plugins-in-swift/
    
    @discardableResult
    /// 添加子控制器
    func add<T: UIViewController>(_ child: T) -> T {
        base.addChild(child)
        base.view.addSubview(child.view)
        child.didMove(toParent: base)
        return child
    }
    
    /// 从父控制器移除
    func remove() {
        guard base.parent != nil else { return }
        base.didMove(toParent: nil)
        base.view.removeFromSuperview()
        base.removeFromParent()
    }
}

// MARK: - Navigation

public extension ExtWrapper where Base: UINavigationController {
    
    /**
     Reference:
        - https://stackoverflow.com/questions/1792858/how-do-i-get-the-rootviewcontroller-from-a-pushed-controller
        - https://stackoverflow.com/questions/10281545/removing-viewcontrollers-from-navigation-stack
     */
    
    /// 导航控制器的根控制器
    var rootViewController: UIViewController? { base.viewControllers.first }
    
    /// 删除导航 stack 控制器
    ///
    /// - Parameter cls: 控制器类型
    func removeController(_ cls: AnyClass) {
        removeControllers([cls])
    }
    
    /// 删除导航 stack 多个控制器
    ///
    /// - Parameter clss: 控制器类型列表
    func removeControllers(_ clss: [AnyClass]) {
        var controllers = base.viewControllers
        let current = controllers.removeLast()
        for (index, controller) in controllers.enumerated().reversed() {
            for cls in clss {
                if controller.isMember(of: cls) {
                    controllers.remove(at: index)
                }
            }
        }
        controllers.append(current)
        base.setViewControllers(controllers, animated: false)
    }
    
    /// 打印当前导航堆栈
    func logControllers() {
        for vc in base.viewControllers.reversed() {
            print("\(vc)")
        }
    }
}
