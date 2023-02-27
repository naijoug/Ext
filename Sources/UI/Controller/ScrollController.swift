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

// MARK: - ScrollView Dragger

/**
 ScrollView 拖拽逻辑处理
 > 说明 : 上下滑动 ScrollView, 调整 TargetView 的高度
  | ----------- |
  |  TargetView |
  | ----------- |
  |  ScrollView |
  | ----------- |
 **/
public class ScrollViewDragger: ExtInnerLogable {
    public var logLevel: Ext.LogLevel = .default
    
    /**
     Reference:
        - https://stackoverflow.com/questions/2543670/finding-the-direction-of-scrolling-in-a-uiscrollview
     */
    
    /// 拖拽位置
    private var dragOffsetY: CGFloat = 0
    
    private var minRatio: CGFloat = 0
    private var maxRatio: CGFloat = 0
    
    /// 目标调整高度视图
    private weak var targetView: UIView?
    /// 高度更新回调
    private var updateHandler: Ext.DataHandler<CGFloat>?
    
    public init(_ targetView: UIView, updateHandler: Ext.DataHandler<CGFloat>?) {
        self.targetView = targetView
        self.updateHandler = updateHandler
    }
    
    /// 处理滚动状态
    public func handle(_ status: ScrollViewStatus, minRatio: CGFloat, maxRatio: CGFloat) {
        self.minRatio = minRatio
        self.maxRatio = maxRatio
        guard minRatio > 0, maxRatio > 0, maxRatio > minRatio else { return }
        //ext.log("status: \(status)")
        switch status {
        case .willBeginDragging(let scrollView):
            ext.log("will begin draging dragOffsetY: \(dragOffsetY)")
            // 记录拖拽位置
            dragOffsetY = scrollView.contentOffset.y
        case .didScroll(let scrollView):
            guard scrollView.isDragging, scrollView.isTracking else { return }
            //ext.log("\(scrollView.isDragging) | \(scrollView.isTracking)")
            let vel = scrollView.panGestureRecognizer.velocity(in: scrollView)
            let deltaY = scrollView.contentOffset.y - dragOffsetY
            ext.log("didScroll | deltaY: \(deltaY) | vel: \(vel)")
            self.handleDragging(scrollView, deltaY: deltaY)
        case .willEndDragging(let scrollView, let velocity, let targetContentOffset):
            let targetOffsetY = targetContentOffset.pointee.y
            let deltaY = targetOffsetY - dragOffsetY
            ext.log("willEndDragging | dragOffsetY: \(dragOffsetY) | targetOffsetY: \(targetOffsetY) | deltaY: \(deltaY) | vel: \(velocity)")
            self.handleDragging(scrollView, deltaY: deltaY, velocityY: velocity.y, isEnd: true)
        default: ()
        }
    }
    
    private func handleDragging(_ scrollView: UIScrollView, deltaY: CGFloat, velocityY: CGFloat = 0, isEnd: Bool = false) {
        guard let targetView = targetView else { return }
        
        let offsetY = scrollView.contentOffset.y
        ext.log("isEnd: \(isEnd) | deltaY: \(deltaY) | dragOffsetY: \(dragOffsetY) | offsetY: \(offsetY)")
        guard deltaY != 0 else { return }
        
        let currentW = targetView.frame.width.rounded()
        let currentH = targetView.frame.height.rounded()
        guard currentW > 0 else { return }
        
        if offsetY == 0, dragOffsetY != 0 {
            dragOffsetY = offsetY
            ext.log("回零")
            return
        }
        
        let minH = (minRatio * currentW).rounded()
        let maxH = (maxRatio * currentW).rounded()
        
        var targetH = max(minH, min(maxH, currentH - deltaY)).rounded()
        
        ext.log("height: \(minH) ~ \(maxH) | currentH \(currentH) -> targetH \(targetH)")
        
        guard isEnd else {
            ext.log("拖动中:")
            if deltaY > 0 {
                let upEnabled = currentH > minH
                ext.log("     向上推 \(upEnabled)")
                guard upEnabled else { return }
            } else {
                let downEnabled = currentH < maxH
                ext.log("     向下拉 \(downEnabled)")
                guard downEnabled else { return }
            }
            guard currentH != targetH else { return }
            ext.log("     目标视图高度改变: \(currentH) -> \(targetH)")
            
            scrollView.contentOffset.y = dragOffsetY
            updateHandler?(targetH)
            return
        }
        ext.log("拖动结束:")
        if velocityY == 0 {
            ext.log("     无加速度")
            if targetH < minH {
                ext.log("     最小化")
                targetH = minH
            } else {
                ext.log("     最小 ~ 最大中间")
                guard offsetY <= 0 else { return }
            }
        } else {
            ext.log("     有加速度 \(velocityY)")
            if velocityY > 0 { // 向上
                ext.log("     向上推")
                targetH = minH
            } else { // 向下
                ext.log("     向下拉 \(targetH)")
                guard offsetY <= 0 else { return }
                targetH = maxH
            }
        }
        adjust(targetView, targetH: targetH)
    }
    
    /// 调整高度
    private func adjust(_ targetView: UIView, targetH: CGFloat, completion handler: Ext.VoidHandler? = nil) {
        let currentH = targetView.frame.height.rounded()
        guard currentH != targetH else {
            ext.log("不需要改变高度")
            handler?()
            return
        }
        ext.log("目标视图改变高度... \(currentH) -> \(targetH)")
        UIView.animate(withDuration: 0.3) {
            self.updateHandler?(targetH)
            targetView.superview?.layoutIfNeeded()
        } completion: { _ in
            handler?()
        }
    }
}
