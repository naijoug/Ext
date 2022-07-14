//
//  UIButton+Ext.swift
//  Ext
//
//  Created by guojian on 2022/7/14.
//

import UIKit

public extension ExtWrapper where Base == UIButton {
    
    /// 设置 UIButton 内容 padding
    /// - Parameter contentInsets: 四周 padding
    func padding(_ contentInsets: UIEdgeInsets) {
        if #available(iOS 15, *) {
            base.configuration?.contentInsets = contentInsets.ext.directionalEdgeInsets
        } else {
            base.contentEdgeInsets = contentInsets
        }
    }
}
