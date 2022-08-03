//
//  UIViewController+Unique.swift
//  Ext
//
//  Created by naijoug on 2022/5/18.
//

import UIKit

extension ExtWrapper where Base: UIViewController {
    /**
     控制器唯一性(相邻页面不重复)功能
     实现 UniqueController 协议的控制器，push 导航时会移除相邻 unique 相同的控制器
     */
    static func unique() {
        UIViewController.unique()
    }
}

public protocol UniqueController: UIViewController {
    /// 唯一标记
    var unique: String { get }
}
private extension UniqueController {
    /// 删除导航堆栈相邻控制器重复
    func remove() {
        Ext.debug("\(navigationController?.viewControllers ?? [])")
        guard let controllers = navigationController?.viewControllers, controllers.count >= 2 else { return }
        let count = controllers.count
        let prev = controllers[count - 2]
        let current = controllers[count - 1]
        Ext.debug("\(prev.ext.typeFullName) -> \(current.ext.typeName) | prev: \(prev) -> current: \(current)")
        guard prev.ext.typeFullName == current.ext.typeFullName else { return }
        Ext.debug("type equal => ")
        guard let prevUnique = prev as? UniqueController,
              let currentUnique = current as? UniqueController else { return }
        Ext.debug("\(prevUnique.unique) vs \(currentUnique.unique)")
        guard prevUnique.unique == currentUnique.unique else { return }
        navigationController?.viewControllers.remove(at: count - 2)
        Ext.debug("result: \(navigationController?.viewControllers ?? [])")
    }
}

private extension UIViewController {
    
    static func unique() {
        ext.swizzlingInstanceMethod(self, original: #selector(viewDidLoad), swizzled: #selector(unique_viewDidLoad))
    }
    
    @objc
    func unique_viewDidLoad() {
        unique_viewDidLoad()
        Ext.debug("unique", tag: .target, logEnabled: false)
        (self as? UniqueController)?.remove()
    }
}
