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

// MARK: - NestedTableView

open class NestedTableView: UITableView, UIGestureRecognizerDelegate {
    /// 可以同时滚动的手势
    var scrollRecongnizers = [UIGestureRecognizer]()
    
    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return scrollRecongnizers.contains(otherGestureRecognizer)
//        return true
    }
}

// MARK: - NestedCell

open class NestedCell: ExtTableCell {
    open var nestedView: UIView? {
        didSet {
            guard let view = nestedView else { return }
            contentView.addSubview(view)
            view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
            view.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
            view.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
            view.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        }
    }
}

// MARK: - NestedScrollController

open class NestedScrollController: UIViewController {
    
    open lazy var tableView: NestedTableView = {
        let tableView = NestedTableView()
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.ext.registerClass(NestedCell.self)
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        return tableView
    }()
    
    private var canScroll: Bool = true      // 父视图是否可滚动
    private var subCanScroll: Bool = false  // 子视图是否可滚动
    
    /// 下拉刷新
    var headerRefreshHandler: Ext.VoidHandler?
    
    /// 父视图滚动最大偏移
    open var maxOffsetY: CGFloat = 0
    /// 子视图可滚动的控制器
    open var subScrollItems = [SubScrollController]()
    
// MARK: - Lifecyle
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        setupData()
        
        for item in subScrollItems {
            addChild(item)
            item.delegate = self
            if let scrollView = item.canScrollView() {
                scrollView.alwaysBounceVertical = true
                tableView.scrollRecongnizers.append(contentsOf: scrollView.gestureRecognizers ?? [])
            }
        }
        
    }
    
    /// 子类重载，初始化数据
    open func setupData() {}
    
}

extension NestedScrollController: UIScrollViewDelegate, SubScrollControllerDelegate {
    
    /// 是否打印滚动日志
    private var scrollLog: Bool { return true }
    
    /// 父滚动视图，滚动回调
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        guard scrollView == tableView else { return }
        
        guard canScroll else { // 父滚动视图不能滚动
            scrollView.contentOffset.y = maxOffsetY
            return
        }
        
        if offsetY >= maxOffsetY { // 父视图滑动到顶端 => 父视图不能滑动，子视图可以滑动
            canScroll = false
            subCanScroll = true
            scrollView.contentOffset.y = maxOffsetY
        }
    }
    
    /// 子滚动视图，滚动回调
    open func subScrollController(_ controller: SubScrollController, didScroll scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        guard subCanScroll else { // 子滚动视图不能滚动
            scrollView.contentOffset.y = 0
            return
        }
        
        if offsetY <= 0 { // 子滑动视图滑动到顶端 => 父视图能滑动，子视图不能滑动
            canScroll = true
            subCanScroll = false
            
            // 调整所有子滚动视图偏移到顶端
            for item in subScrollItems {
                if let subScrollView = item.canScrollView() {
                    subScrollView.contentOffset.y = 0
                }
            }
        }
        // 更新指示条显示状态
        scrollView.showsVerticalScrollIndicator = subCanScroll
    }
    
}

// MARK: - UITableView

extension NestedScrollController: UITableViewDataSource, UITableViewDelegate {
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.ext.dequeueReusableCell(NestedCell.self, for: indexPath)
        return cell
    }
    
    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.frame.height
    }
    
    open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    open func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    open func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
}

// MARK: - SubScrollController

public protocol SubScrollControllerDelegate: AnyObject {
    func subScrollController(_ controller: SubScrollController, didScroll scrollView: UIScrollView)
}

/// 可滚动的子控制器基类
open class SubScrollController: UIViewController, UIScrollViewDelegate {
    weak var delegate: SubScrollControllerDelegate?
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    open func canScrollView() -> UIScrollView? {
        return nil
    }
    
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == canScrollView() {
            delegate?.subScrollController(self, didScroll: scrollView)
        }
    }
}
