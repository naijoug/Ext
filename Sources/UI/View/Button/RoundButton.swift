//
//  RoundButton.swift
//  Ext
//
//  Created by guojian on 2021/6/21.
//

import UIKit

/// 圆角按钮
open class RoundButton: IndicatorButton {
    public enum RoundCornerType {
        /// 没有圆角
        case none
        /// 普通圆角
        case normal(_ radius: CGFloat)
        /// 半圆角
        case circle
    }
    
    /// 圆角类型
    public var type: RoundCornerType = .normal(4) {
        didSet {
            setNeedsLayout()
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        var roundRadius: CGFloat = 0
        switch type {
        case .none:                 roundRadius = 0
        case .normal(let radius):   roundRadius = radius
        case .circle:               roundRadius = frame.height/2
        }
        ext.roundCorner(radius: roundRadius)
    }
}
