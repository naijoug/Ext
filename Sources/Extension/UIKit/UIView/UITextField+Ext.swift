//
//  UITextField+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/28.
//

import UIKit

public extension ExtWrapper where Base: UITextField {
    
    // Reference: https://stackoverflow.com/questions/25367502/create-space-at-the-beginning-of-a-uitextfield
    
    enum PaddingSpace {
        case left(CGFloat)
        case right(CGFloat)
        case equalSpace(CGFloat)
    }
    
    func addPadding(_ padding: PaddingSpace) {
        
        func addLeftSpace(_ space: CGFloat) {
            base.leftView = UIView(frame: CGRect(x: 0, y: 0, width: space, height: base.frame.height))
            base.leftViewMode = .always
        }
        func addRightSpace(_ space: CGFloat) {
            base.rightView = UIView(frame: CGRect(x: 0, y: 0, width: space, height: base.frame.height))
            base.rightViewMode = .always
        }
        
        switch padding {
        case .left(let space):          addLeftSpace(space)
        case .right(let space):         addRightSpace(space)
        case .equalSpace(let space):    addLeftSpace(space); addRightSpace(space)
        }
    }
}
