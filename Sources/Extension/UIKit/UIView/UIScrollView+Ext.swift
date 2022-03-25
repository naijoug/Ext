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


public extension UIScrollView {
    private static var pageControllerIndexKey: UInt8 = 0
    var pageControllerIndex: Int? {
        get {
            ext.getAssociatedObject(&Self.pageControllerIndexKey, valueType: Int.self)
        }
        set {
            ext.setAssociatedObject(&Self.pageControllerIndexKey, value: newValue, policy: .assign)
        }
    }
}

public extension ExtWrapper where Base: UIPageViewController {
    
    /**
     Reference:
        - https://stackoverflow.com/questions/21798218/disable-uipageviewcontroller-bounce
        - https://stackoverflow.com/questions/23267929/combine-uipageviewcontroller-swipes-with-ios-7-uinavigationcontroller-back-swipe/33217469
     */
    
    /**
     UIPageViewController 中的 scrollView
       类型为: _UIQueuingScrollView, 为 UIScrollView 的子类
     */
    var scrollView: UIScrollView? {
        if let scrollView = base.view as? UIScrollView {
            return scrollView
        }
        for subview in base.view.subviews where subview is UIScrollView {
            return subview as? UIScrollView
        }
        return nil
    }
    
}
