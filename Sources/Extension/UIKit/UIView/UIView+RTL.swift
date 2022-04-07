//
//  UIView+RTL.swift
//  Ext
//
//  Created by guojian on 2022/4/7.
//

import UIKit

/**
 Reference:
    - https://stackoverflow.com/questions/25598194/aligning-right-to-left-on-uicollectionview
    -
 */

public extension ExtWrapper where Base: UIApplication {
    /// App 当前是否为 RTL(right to left) 布局系统
    var isRTL: Bool { base.userInterfaceLayoutDirection == .rightToLeft }
}

public extension ExtWrapper where Base: UIView  {
    
    /// 当前是否为 RTL(right to left) 布局系统 (首选语言为: 阿拉伯语、波斯语...)
    static var isRTL: Bool {
        UIView.userInterfaceLayoutDirection(for: UIView.appearance().semanticContentAttribute) == .rightToLeft
    }
    
    /// 水平翻转 (如果为左对齐布局，则进行水平翻转)
    /// - Parameter isRTL: 是否左对齐
    func flipsHorizontallyIfNeeded(_ isRTL: Bool = UIView.ext.isRTL) {
        base.transform = isRTL ? CGAffineTransform(scaleX: -1, y: 1) : .identity
    }
    
    /// set RTL enabled
    func enabledRTL() {
        flipsHorizontallyIfNeeded()
    }
}

public extension ExtWrapper where Base: UIImage {
    
    /// RTL 图片 (用于进行 LTR 图片翻转)
    var imageRTL: UIImage? {
        guard let cgImage = base.cgImage, UIView.ext.isRTL else { return base }
        return UIImage(cgImage: cgImage, scale: base.scale, orientation: .upMirrored)
    }
    
}
