//
//  NestedScrollController.swift
//  Ext
//
//  Created by naijoug on 2020/3/23.
//

import UIKit

/**
 Reference:
    - https://stackoverflow.com/questions/44473232/twitter-profile-page-ios-swift-dissection-multiple-uitableviews-in-uiscrollview
 */

/// 嵌套内部滚动视图协议
public protocol NestedInnerViewScrollable {
    /// 内部滚动的视图
    var innerScrollView: UIScrollView { get }
    /// 内部视图滚动回调
    var didInnerScrollHandler: Ext.VoidHandler? { get set }
}

/// 可嵌套滚动视图
private class NestedScrollView: UIScrollView, UIGestureRecognizerDelegate {
    /// 可以同时滚动的手势
    var scrollRecongnizers = [UIGestureRecognizer]()
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return scrollRecongnizers.contains(otherGestureRecognizer)
    }
}

/// 可嵌套滚动控制器
open class NestedScrollController: UIViewController, ExtInnerLogable {
    public var logLevel: Ext.LogLevel = .off
    
    private lazy var nestedScrollView: NestedScrollView = {
        let scrollView = view.ext.add(NestedScrollView())
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        return scrollView
    }()
    public var scrollView: UIScrollView { nestedScrollView }
    
    /// 内嵌是视图容器
    public lazy var contentView: UIView = {
        let contentView = nestedScrollView.ext.add(UIView())
        contentView.translatesAutoresizingMaskIntoConstraints = false
        let contentViewHeightAnchor = contentView.heightAnchor.constraint(equalTo: view.heightAnchor)
        contentViewHeightAnchor.priority = UILayoutPriority(rawValue: 1)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: nestedScrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: nestedScrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: nestedScrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: nestedScrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: view.widthAnchor),
            contentViewHeightAnchor
        ])
        return contentView
    }()
    
// MARK: - Status
    
    /// 外部视图是否可滚动
    private var outerScrollable: Bool = true
    /// 内部视图是否可滚动
    private var innerScrollable: Bool = false
    
// MARK: - Data
    
    /// 外部视图滚动最大偏移
    public var outerMaxOffsetY: CGFloat = 0
    /// 内部可滚动
    public var innerItems = [NestedInnerViewScrollable]() {
        didSet {
            for var item in innerItems {
                nestedScrollView.scrollRecongnizers.append(contentsOf: item.innerScrollView.gestureRecognizers ?? [])
                item.innerScrollView.showsVerticalScrollIndicator = true
                item.didInnerScrollHandler = { [weak self] in
                    guard let `self` = self else { return }
                    self.innerScrollViewDidScroll(item.innerScrollView)
                }
            }
        }
    }
    
// MARK: - Lifecyle
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        nestedScrollView.ext.active()
        contentView.ext.active()
    }
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        ext.log("contentSize: \(nestedScrollView.contentSize)")
    }
}

extension NestedScrollController: UIScrollViewDelegate {
    
    /// 外部滚动视图，滚动回调
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == self.nestedScrollView else { return }
        
        let offsetY = scrollView.contentOffset.y
        ext.log("outer scroll | offsetY: \(offsetY) | outerScrollable \(outerScrollable) | innerScrollable: \(innerScrollable) | outerMaxOffsetY: \(outerMaxOffsetY)")
        guard outerScrollable else {
            ext.log("外部视图不能滚动")
            scrollView.contentOffset.y = outerMaxOffsetY
            return
        }
        
        if offsetY >= outerMaxOffsetY {
            ext.log("外部视图滑动到顶端 => 外部视图不能滑动，内部视图可以滑动")
            outerScrollable = false
            innerScrollable = true
            scrollView.contentOffset.y = outerMaxOffsetY
        }
    }
    /// 内部滚动视图，滚动回调
    private func innerScrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        ext.log("inner scroll | offsetY: \(offsetY) | outerScrollable \(outerScrollable) | innerScrollable: \(innerScrollable) | outerMaxOffsetY: \(outerMaxOffsetY)")
        guard innerScrollable else {
            ext.log("内部视图不能滚动")
            scrollView.contentOffset.y = 0
            return
        }
        
        if offsetY <= 0 {
            ext.log("内部视图滑动到顶端 => 外部视图能滑动，内部视图不能滑动")
            outerScrollable = true
            innerScrollable = false
            
            // 调整所有子滚动视图偏移到顶端
            for item in innerItems {
                guard scrollView != item.innerScrollView else { continue }
                item.innerScrollView.contentOffset.y = 0
            }
        }
        // 更新指示条显示状态
        scrollView.showsVerticalScrollIndicator = outerScrollable
    }
}
