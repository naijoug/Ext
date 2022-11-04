//
//  VerticallyCenteredTextView.swift
//  Ext
//
//  Created by guojian on 2022/10/14.
//

import UIKit

/// 垂直居中 textView
open class VerticallyCenteredTextView: PlaceholderTextView {
    // Reference: https://stackoverflow.com/questions/12591192/center-text-vertically-in-a-uitextview
    public override var contentSize: CGSize {
        didSet {
            var topCorrection = (bounds.size.height - contentSize.height * zoomScale) / 2.0
            topCorrection = max(0, topCorrection)
            contentInset = UIEdgeInsets(top: topCorrection, left: 0, bottom: 0, right: 0)
        }
    }
}


