//
//  ScrollController.swift
//  Ext
//
//  Created by guojian on 2022/3/9.
//

import UIKit

/// 滚动视图状态
public enum ScrollViewStatus {
    case didScroll(_ scrollView: UIScrollView)
    
    case willBeginDragging(_ scrollView: UIScrollView)
    case willEndDragging(_ scrollView: UIScrollView, _ velocity: CGPoint, _ targetContentOffset: UnsafeMutablePointer<CGPoint>)
    case didEndDragging(_ scrollView: UIScrollView, _ decelerate: Bool)
    
    case willBeginDecelerating(_ scrollView: UIScrollView)
    case didEndDecelerating(_ scrollView: UIScrollView)
}
public extension ScrollViewStatus {
    var scrollView: UIScrollView {
        switch self {
        case .didScroll(let scrollView): return scrollView
            
        case .willBeginDragging(let scrollView): return scrollView
        case .willEndDragging(let scrollView, _, _): return scrollView
        case .didEndDragging(let scrollView, _): return scrollView
        
        case .willBeginDecelerating(let scrollView): return scrollView
        case .didEndDecelerating(let scrollView): return scrollView
        }
    }
}
public extension ScrollViewStatus {
    /// 滚动状态
    enum ScrollStatus {
        /// 其它状态
        case normal
        
        /// 拖拽中
        case dragging
        /// 滚动停止 (无减速停止 || 减速之后停止)
        case scrollToEnd(decelerate: Bool)
        
        public var isDragging: Bool {
            switch self {
            case .dragging: return true
            default: return false
            }
        }
    }
    /// 滚动状态
    var scrollStatus: ScrollStatus {
        switch self {
        case .didScroll(let scrollView):
            guard scrollView.isDragging, scrollView.isTracking else { return .normal }
            return .dragging
        case let .didEndDragging(_, decelerate):
            guard !decelerate else { return .normal }
            return .scrollToEnd(decelerate: false)
        case .didEndDecelerating:
            return .scrollToEnd(decelerate: true)
        default: return .normal
        }
    }
}

/// 控制可滚动协议
public protocol ScrollableController: UIViewController {
    
    typealias ScrollHandler = Ext.DataHandler<ScrollViewStatus>
    
    /// 滚动回调
    var scrollHandler: ScrollHandler? { get set }
}

/// 滚动控制器基类
open class BaseScrollController: UIViewController, ScrollableController {
    
    public var scrollHandler: ScrollHandler?
    
    /// 滚动视图
    open var scrollView: UIScrollView {
        fatalError("sub controller must implemented.")
    }
    
    /// 下拉刷新控件
    open private(set) lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        return refreshControl
    }()
    
    /// 下拉刷新是否可用
    open var pullToRefreshEnabled: Bool = false {
        didSet {
            guard pullToRefreshEnabled else {
                refreshControl.removeFromSuperview()
                return
            }
            scrollView.addSubview(refreshControl)
        }
    }
    
    /// 下拉刷新
    @objc
    open func pullToRefresh() {}
}

// MARK: - Delegate

extension BaseScrollController: UIScrollViewDelegate {
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollHandler?(.didScroll(scrollView))
    }
    
    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollHandler?(.willBeginDragging(scrollView))
    }
    open func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        scrollHandler?(.willEndDragging(scrollView, velocity, targetContentOffset))
    }
    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollHandler?(.didEndDragging(scrollView, decelerate))
    }
    
    open func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        scrollHandler?(.willBeginDecelerating(scrollView))
    }
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollHandler?(.didEndDecelerating(scrollView))
    }
}
