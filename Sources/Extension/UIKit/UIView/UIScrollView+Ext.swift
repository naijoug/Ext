//
//  UIScrollView+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/28.
//

import UIKit

extension ExtWrapper where Base: UIScrollView {
    
    /// 滚动到顶部
    public func scrollToTop(animated: Bool = true) {
        guard base.contentOffset.x != 0 || base.contentOffset.y != 0 else { return }
        base.setContentOffset(.zero, animated: animated)
    }
    
    /// 滚动到底部
    public func scrollToBottom(animated: Bool = true) {
        let y = base.contentSize.height - base.frame.size.height + base.contentInset.bottom
        guard y > 0 else { return }
        base.setContentOffset(CGPoint(x: 0, y: y), animated: animated)
    }
    
    /// 停止滚动
    public func stopScroll() {
        base.setContentOffset(base.contentOffset, animated: false)
    }
    
}
