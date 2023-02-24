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
        Ext.log("\(navigationController?.viewControllers ?? [])")
        guard var controllers = navigationController?.viewControllers, controllers.count >= 2 else { return }
        let count = controllers.count
        let prev = controllers[count - 2]
        let current = controllers[count - 1]
        Ext.log("\(prev.ext.typeFullName) -> \(current.ext.typeName) | prev: \(prev) -> current: \(current)")
        guard prev.ext.typeFullName == current.ext.typeFullName else { return }
        Ext.log("type equal => ")
        guard let prevUnique = prev as? UniqueController,
              let currentUnique = current as? UniqueController else { return }
        Ext.log("\(prevUnique.unique) vs \(currentUnique.unique)")
        guard prevUnique.unique == currentUnique.unique else { return }
        let controller = controllers.remove(at: count - 2)
        controller.removeFromParent()
        navigationController?.setViewControllers(controllers, animated: false)
        //navigationController?.viewControllers.remove(at: count - 2)
        Ext.log("result: \(controller) | \(controllers) | \(navigationController?.viewControllers ?? [])")
    }
}

private extension UIViewController {
    
    static func unique() {
        ext.swizzlingInstanceMethod(self, original: #selector(viewDidLoad), swizzled: #selector(unique_viewDidLoad))
    }
    
    @objc
    func unique_viewDidLoad() {
        unique_viewDidLoad()
        (self as? UniqueController)?.remove()
    }
}
