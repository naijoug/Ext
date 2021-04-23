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
        */
        base.isTranslucent = isTransparent
        base.shadowImage = isTransparent ? UIImage() : nil
        base.setBackgroundImage(isTransparent ? UIImage() : nil, for: .default)
    }
}
