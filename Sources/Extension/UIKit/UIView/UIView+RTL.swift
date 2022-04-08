//
//  UIView+RTL.swift
//  Ext
//
//  Created by guojian on 2022/4/7.
//

import UIKit

/**
 Reference:
    - https://developer.apple.com/design/human-interface-guidelines/right-to-left/overview/introduction/
    - https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPInternational/SupportingRight-To-LeftLanguages/SupportingRight-To-LeftLanguages.html
    - https://stackoverflow.com/questions/25598194/aligning-right-to-left-on-uicollectionview
    - https://stackoverflow.com/questions/33130331/uicollectionview-ios-9-issue-on-project-with-rtl-languages-support
    - https://stackoverflow.com/questions/37497610/ios-rtl-improperly-displaying-english-inside-rtl-string
    - https://www.jianshu.com/p/4fcf4a6710a1
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
    
    /**
     设置 RTL 布局生效
     特殊说明:
        UICollectionViewCell & UITableViewCell 需要设置 contentView
     */
    func enabledRTL() {
        flipsHorizontallyIfNeeded()
    }
}

public extension ExtWrapper where Base: UIImage {
    
    /// RTL 图片 (用于进行 LTR 图片翻转)
    var imageRTL: UIImage? {
        return UIView.ext.isRTL ? base.imageFlippedForRightToLeftLayoutDirection() : base
        //guard let cgImage = base.cgImage, UIView.ext.isRTL else { return base }
        //return UIImage(cgImage: cgImage, scale: base.scale, orientation: .upMirrored)
    }
    
}

public extension ExtWrapper where Base == String {

    /** 是否为包含 RTL 前缀标识的字符串
     前缀说明
        \u200E : LTR 布局
        \u200F : RTL 布局
     */
    var isRTLString: Bool {
        base.hasPrefix("\u{200E}") || base.hasPrefix("\u{200F}")
    }
    
    /// RTL 字符串
    var stringRTL: String {
        "\(UIView.ext.isRTL ? "\u{200F}" : "\u{200E}")\(base)\u{200c}"
    }
}
