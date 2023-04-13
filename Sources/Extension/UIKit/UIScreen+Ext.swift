//
//  UIScreen+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/28.
//

import UIKit

public extension ExtWrapper where Base == UIScreen {
    
    /// 屏幕宽
    static var screenWidth: CGFloat { Base.main.bounds.size.width }
    /// 屏幕高
    static var screenHeight: CGFloat { Base.main.bounds.size.height }
    
}
