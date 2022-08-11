//
//  UITextField+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/28.
//

import UIKit

public extension ExtWrapper where Base: UITextField {
    
    // Reference: https://stackoverflow.com/questions/25367502/create-space-at-the-beginning-of-a-uitextfield
    
    func addPadding(left: CGFloat = 0, right: CGFloat = 0) {
        if left > 0 {
            base.leftView = UIView(frame: CGRect(x: 0, y: 0, width: left, height: base.frame.height))
            base.leftViewMode = .always
        }
        if right > 0 {
            base.rightView = UIView(frame: CGRect(x: 0, y: 0, width: right, height: base.frame.height))
            base.rightViewMode = .always
        }
    }
    
}
