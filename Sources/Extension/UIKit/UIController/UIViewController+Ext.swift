//
//  UIViewController+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/28.
//

import UIKit

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
    enum NavBarPostion {
        case left
        case right
    }
    
    /// 设置 pop 关闭页面的导航栏 item 图片
    /// - Parameters:
    ///   - image: 图片
    ///   - position: 导航栏位置
    func setPopImage(_ image: UIImage?, position: NavBarPostion = .left) {
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
    func setDismissImage(_ image: UIImage?, position: NavBarPostion = .left) {
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
     导航控制器的根控制器
     Reference:
        - https://stackoverflow.com/questions/1792858/how-do-i-get-the-rootviewcontroller-from-a-pushed-controller
     */
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
        var vcs = base.viewControllers
        let current = vcs.removeLast()
        for (index, vc) in vcs.enumerated().reversed() {
            for cls in clss {
                if vc.isMember(of: cls) {
                    vcs.remove(at: index)
                }
            }
        }
        vcs.append(current)
        base.setViewControllers(vcs, animated: false)
    }
    
    /// 打印当前导航堆栈
    func logControllers() {
        for vc in base.viewControllers.reversed() {
            print("\(vc)")
        }
    }
}
