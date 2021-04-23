//
//  UIScreen+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/28.
//

import UIKit

public extension ExtWrapper where Base == UIScreen {
    
    /// 屏幕宽
    var screenWidth: CGFloat { return base.bounds.size.width }
    /// 屏幕高
    var screenHeight: CGFloat { return base.bounds.size.height }
    
}
