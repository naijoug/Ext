//
//  UITabBar+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/28.
//

import UIKit

public extension ExtWrapper where Base: UITabBar {
    
    // Reference: https://stackoverflow.com/questions/39850794/remove-top-line-from-tabbar
    
    /// 移除顶部分割线
    func removeTopLine() {
        if #available(iOS 13.0, *) {
            let appearance = base.standardAppearance
            appearance.shadowImage = nil
            appearance.shadowColor = nil
            base.standardAppearance = appearance
        } else {
            base.shadowImage = UIImage()
            base.backgroundImage = UIImage()
        }
    }
}
