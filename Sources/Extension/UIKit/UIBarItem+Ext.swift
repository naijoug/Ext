//
//  UIBarItem+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/28.
//

import UIKit

public extension ExtWrapper where Base: UIBarItem {
    
    // Reference: https://stackoverflow.com/questions/14318368/uibarbuttonitem-how-can-i-find-its-frame
    
    /// 返回 UIBarItem 的视图
    var view: UIView? { return base.value(forKey: "view") as? UIView }
    
}
