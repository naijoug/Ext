//
//  UIButton+Ext.swift
//  Ext
//
//  Created by guojian on 2022/7/14.
//

import UIKit

public extension ExtWrapper where Base: UIButton {
    
    /// 设置 UIButton 内容 padding
    /// - Parameter contentInsets: 四周 padding
    func padding(top: CGFloat = 0, leading: CGFloat = 0, bottom: CGFloat = 0, trailing: CGFloat = 0) {
        let contentInsets = NSDirectionalEdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing)
        if #available(iOS 15, *), var configuration = base.configuration {
            configuration.contentInsets = contentInsets
            base.configuration = configuration
        } else {
            base.contentEdgeInsets = contentInsets.ext.uiEdgeInsets
        }
    }
}
