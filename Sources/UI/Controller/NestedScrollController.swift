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

// MARK: - InnerScrollController

/// 内部滚动控制器
protocol InnerScrollControllerDelegate: AnyObject {
    func innerScrollController(_ controller: InnerScrollController, didScroll scrollView: UIScrollView)
}

/// 可滚动的内部控制器
open class InnerScrollController: UIViewController, UIScrollViewDelegate {
    weak var delegate: InnerScrollControllerDelegate?
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    /// 内部滚动视图 (子内实现)
    open var innerScrollView: UIScrollView? { nil }
    
    /// 滚动协议
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == innerScrollView {
            delegate?.innerScrollController(self, didScroll: scrollView)
        }
    }
}

// MARK: - NestedScrollController

/// 可嵌套滚动视图
private class NestedScrollView: UIScrollView, UIGestureRecognizerDelegate {
    /// 可以同时滚动的手势
    var scrollRecongnizers = [UIGestureRecognizer]()
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return scrollRecongnizers.contains(otherGestureRecognizer)
    }
}

/// 可嵌套滚动控制器
open class NestedScrollController: UIViewController {
    
    private lazy var scrollView: NestedScrollView = {
        let scrollView = view.ext.add(NestedScrollView())
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        return scrollView
    }()
    
    /// 内嵌是视图容器
    public lazy var contentView: UIView = {
        let contentView = scrollView.ext.add(UIView())
        contentView.translatesAutoresizingMaskIntoConstraints = false
        let contentViewHeightAnchor = contentView.heightAnchor.constraint(equalTo: view.heightAnchor)
        contentViewHeightAnchor.priority = UILayoutPriority(rawValue: 1)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leftAnchor.constraint(equalTo: scrollView.leftAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.rightAnchor.constraint(equalTo: scrollView.rightAnchor),
            contentView.widthAnchor.constraint(equalTo: view.widthAnchor),
            contentViewHeightAnchor
        ])
        return contentView
    }()
    
// MARK: - Status
    
    public var logEnabled: Bool = true
    
    /// 外部视图是否可滚动
    private var outerScrollable: Bool = true
    /// 内部视图是否可滚动
    private var innerScrollable: Bool = false
    
    /// 外部视图滚动最大偏移
    public var outerMaxOffsetY: CGFloat = 0
    /// 内部可滚动的控制器
    open var innerScrollControllers: [InnerScrollController] { [] }
    
// MARK: - Lifecyle
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.ext.active()
        contentView.ext.active()
        
        for controller in innerScrollControllers {
            addChild(controller)
            controller.delegate = self
            if let innerScrollView = controller.innerScrollView {
                innerScrollView.alwaysBounceVertical = true
                scrollView.scrollRecongnizers.append(contentsOf: innerScrollView.gestureRecognizers ?? [])
            }
        }
    }
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        Ext.debug("contentSize: \(scrollView.contentSize)", logEnabled: logEnabled)
    }
}

extension NestedScrollController: UIScrollViewDelegate, InnerScrollControllerDelegate {
    
    /// 外部滚动视图，滚动回调
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == self.scrollView else { return }
        
        let offsetY = scrollView.contentOffset.y
        Ext.debug("outer scroll | offsetY: \(offsetY) | outerScrollable \(outerScrollable) | innerScrollable: \(innerScrollable) | outerMaxOffsetY: \(outerMaxOffsetY)", logEnabled: logEnabled)
        guard outerScrollable else {
            Ext.debug("外部视图不能滚动", logEnabled: logEnabled)
            scrollView.contentOffset.y = outerMaxOffsetY
            return
        }
        
        if offsetY >= outerMaxOffsetY {
            Ext.debug("外部视图滑动到顶端 => 外部视图不能滑动，内部视图可以滑动", logEnabled: logEnabled)
            outerScrollable = false
            innerScrollable = true
            scrollView.contentOffset.y = outerMaxOffsetY
        }
    }
    
    /// 内部滚动视图，滚动回调
    public func innerScrollController(_ controller: InnerScrollController, didScroll scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        Ext.debug("innser scroll | offsetY: \(offsetY) | outerScrollable \(outerScrollable) | innerScrollable: \(innerScrollable) | outerMaxOffsetY: \(outerMaxOffsetY)", logEnabled: logEnabled)
        guard innerScrollable else {
            Ext.debug("内部视图不能滚动", logEnabled: logEnabled)
            scrollView.contentOffset.y = 0
            return
        }
        
        if offsetY <= 0 {
            Ext.debug("内部视图滑动到顶端 => 外部视图能滑动，内部视图不能滑动", logEnabled: logEnabled)
            outerScrollable = true
            innerScrollable = false
            
            // 调整所有子滚动视图偏移到顶端
            for controller in innerScrollControllers {
                if let innerScrollView = controller.innerScrollView {
                    innerScrollView.contentOffset.y = 0
                }
            }
        }
        // 更新指示条显示状态
        scrollView.showsVerticalScrollIndicator = outerScrollable
    }
}
