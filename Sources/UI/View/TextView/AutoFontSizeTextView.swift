//
//  AutoFontSizeTextView.swift
//  Ext
//
//  Created by guojian on 2022/10/14.
//

import UIKit

/// 自动缩放字体大小 textView
public class AutoFontSizeTextView: VerticallyCenteredTextView {
    
    private var minFontSize: CGFloat = 6
    private var maxFontSize: CGFloat = 60
    
    /// 自动缩放字体尺寸范围
    /// - Parameters:
    ///   - min: 最小值 (默认: 6)
    ///   - max: 最大值 (默认: 60)
    public func autoFontSize(min: CGFloat, max: CGFloat) {
        guard min > 0, max > 0, min < max else { return }
        minFontSize = min
        maxFontSize = max
    }
    
    /// 刷新 TextView 字体
    public func reloadFont() {
        // Solution: https://stackoverflow.com/questions/2038975/resize-font-size-to-fill-uitextview
        guard !text.isEmpty, !bounds.size.equalTo(.zero) else { return }
        
        let currentSize = bounds.size
        let fixedWidth = currentSize.width
        let expectedSize = sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        
        guard expectedSize.height != currentSize.height else {
            Ext.debug("字体不需要缩放")
            return
        }
        Ext.debug("textView font : \(font?.pointSize ?? 0)")
        guard var expectedFont = font else {
            Ext.debug("textView font is nil", tag: .warning)
            return
        }
        Ext.debug("current font: \(expectedFont.pointSize)")
        
        guard expectedSize.height > currentSize.height else {
            Ext.debug("需要将字体放大")
            while sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude)).height < currentSize.height {
                expectedFont = expectedFont.withSize(expectedFont.pointSize + 1)
                guard expectedFont.pointSize <= maxFontSize else { break }
                //Ext.debug("放大字体 \(font?.pointSize ?? 0) -> \(expectedFont.pointSize)")
                font = expectedFont
            }
            return
        }
        Ext.debug("需要将字体缩小")
        while sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude)).height > currentSize.height {
            expectedFont = expectedFont.withSize(expectedFont.pointSize - 1)
            guard expectedFont.pointSize >= minFontSize else { break }
            //Ext.debug("缩小字体: \(font?.pointSize ?? 0) -> \(expectedFont.pointSize)")
            font = expectedFont
        }
    }
}
