//
//  UINavigationBar+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/28.
//

import UIKit

public extension ExtWrapper where Base: UINavigationBar {
    
    /// 移除底部分割线
    func removeBottomLine() {
        // Reference: https://stackoverflow.com/questions/19226965/how-to-hide-uinavigationbar-1px-bottom-line
        base.setValue(true, forKey: "hidesShadow")
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.shadowColor = nil // 用于去掉底部分割线
            base.scrollEdgeAppearance = appearance
            base.standardAppearance = appearance
        }
    }
    
    /// 重置 clipsToBounds 属性，使得 titleView 可以超出导航栏不被裁剪
    func reset(clipsToBounds: Bool) {
        // Solution: https://stackoverflow.com/questions/47121427/make-navigationbars-titleview-larger-than-itself
        for subview in base.subviews {
            //Ext.debug("\(subview)")
            guard subview.clipsToBounds else { continue }
            subview.clipsToBounds = false
            //Ext.debug("clipsToBounds: \(subview)")
        }
    }
    
    /// 导航栏是否透明
    /// - Parameter isTransparent: 是否透明
    func transparent(_ isTransparent: Bool = false) {
        /** Reference:
            - https://stackoverflow.com/questions/2315862/make-uinavigationbar-transparent
            - https://stackoverflow.com/questions/25845855/transparent-navigation-bar-ios
            - https://stackoverflow.com/questions/69111478/ios-15-navigation-bar-transparent
        */
        base.shadowImage = isTransparent ? UIImage() : nil
        base.setBackgroundImage(isTransparent ? UIImage() : nil, for: .default)
        
        if #available(iOS 15.0, *) {
            /*
             iOS 15 导航栏 bug: 背景颜色设置 API 变更
                - https://developer.apple.com/forums/thread/683265
             */
            let appearance = UINavigationBarAppearance()
            isTransparent ? appearance.configureWithTransparentBackground() : appearance.configureWithOpaqueBackground()
            appearance.shadowColor = nil
            appearance.shadowImage = isTransparent ? UIImage() : nil
            appearance.backgroundImage = isTransparent ? UIImage() : nil
            base.scrollEdgeAppearance = appearance
            base.standardAppearance = appearance
        }
    }
}
