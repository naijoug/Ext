//
//  IndicatorButton.swift
//  Ext
//
//  Created by naijoug on 2019/8/13.
//

import UIKit

/// 上下按钮
open class UpdownButton: IndicatorButton {
    
    /// 上下模式
    public enum UpdownMode {
        /// 图片(上) + 文字(下)
        case imageTitle
        /// 文字(上) + 图片(下)
        case titleImage
    }
    
    /// 按钮模式
    open var mode: UpdownMode = .imageTitle
    /// 上下比例
    open var ratio: CGFloat = 0.5
    /// 上下偏移
    open var margin: CGFloat = 0
    
    open override func setupUI() {
        super.setupUI()
     
        titleLabel?.textAlignment = .center
        imageView?.contentMode = .center
    }
    
    open override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        switch mode {
        case .imageTitle: return upRect(contentRect: contentRect)
        case .titleImage: return downRect(contentRect: contentRect)
        }
    }
    open override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        switch mode {
        case .imageTitle: return downRect(contentRect: contentRect)
        case .titleImage: return upRect(contentRect: contentRect)
        }
    }
    
    private func upRect(contentRect: CGRect) -> CGRect {
        let width = contentRect.size.width
        let height = contentRect.size.height
        let upH = (height - margin*2) * ratio
        return CGRect(x: 0, y: margin, width: width, height: upH)
    }
    private func downRect(contentRect: CGRect) -> CGRect {
        let width = contentRect.size.width
        let height = contentRect.size.height
        let donwH = (height - margin*2) * (1 - ratio)
        return CGRect(x: 0, y: (height - donwH - margin), width: width, height: donwH)
    }
    
}
