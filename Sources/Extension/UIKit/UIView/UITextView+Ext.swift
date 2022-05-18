//
//  UITextView+Ext.swift
//  Ext
//
//  Created by naijoug on 2022/5/12.
//

import UIKit

public extension ExtWrapper where Base: UITextView {
    
    func clearPadding() {
        // clear leading trailling padding
        base.textContainer.lineFragmentPadding = 0
        // clear edge inset
        base.textContainerInset = .zero
    }
    
}
