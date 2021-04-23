//
//  NavigationController.swift
//  Ext
//
//  Created by naijoug on 2020/5/27.
//

import UIKit

open class NavigationController: UINavigationController {
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        // Reference: https://stackoverflow.com/questions/24235401/uistatusbarstyle-not-working-in-swift
        guard let vc = viewControllers.last else {
            return .default
        }
        return vc.preferredStatusBarStyle
    }
    
    open override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        viewController.ext.backTitle() // 隐藏导航栏返回按钮文字
        if viewControllers.count > 0 { // 进入子页面隐藏 tabBar
            viewController.hidesBottomBarWhenPushed = true
        }
        super.pushViewController(viewController, animated: animated)
    }
}
