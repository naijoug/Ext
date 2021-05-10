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
    /// - Returns: 当前控制器类型实例
    static func instantiateFromStoryboard(sbName: String) -> Base {
        func instanceFromStoryboard<T>(sbName: String) -> T where T: UIViewController {
            if let vc = UIStoryboard(name: sbName, bundle: nil).instantiateViewController(withIdentifier: "\(Base.self)") as? T {
                return vc
            }
            fatalError("Load storyboard controller failure \(self)")
        }
        return instanceFromStoryboard(sbName: sbName)
    }
    
}

// MARK: -

public extension ExtWrapper where Base: UIViewController {
    
    /// 控制器是否可见
    var isVisible: Bool {
        // Refrence: https://stackoverflow.com/questions/2777438/how-to-tell-if-uiviewcontrollers-view-is-visible
        return base.viewIfLoaded?.window != nil
    }
    
    /// 导航栏返回按钮标题
    func backTitle(_ title: String = "") {
        base.navigationItem.backBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: nil, action: nil)
    }
    
}

// MARK: - Child Controller

public extension ExtWrapper where Base: UIViewController {
    
    // Reference: https://www.swiftbysundell.com/articles/using-child-view-controllers-as-plugins-in-swift/
    
    /// 添加子控制器
    func add(_ child: UIViewController) {
        base.addChild(child)
        base.view.addSubview(child.view)
        child.didMove(toParent: base)
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
