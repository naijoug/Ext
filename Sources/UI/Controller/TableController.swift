//
//  TableController.swift
//  Ext
//
//  Created by naijoug on 2020/5/27.
//

import UIKit

/// 滚动视图状态
public enum ScrollViewStatus {
    case didScroll(_ scrollView: UIScrollView)
    
    case beginDragging(_ scrollView: UIScrollView)
    case willEndDragging(_ scrollView: UIScrollView, _ velocity: CGPoint, _ targetContentOffset: UnsafeMutablePointer<CGPoint>)
    case didEndDragging(_ scrollView: UIScrollView, _ decelerate: Bool)
    
    case beginDecelerating(_ scrollView: UIScrollView)
    case endDecelerating(_ scrollView: UIScrollView)
}

/// 控制可滚动协议
public protocol ControllerScrollable {
    
    typealias ScrollHandler = Ext.DataHandler<ScrollViewStatus>
    
    /// 滚动回调
    var scrollHandler: ScrollHandler? { get set }
}

open class TableController: UIViewController, ControllerScrollable {
    public var scrollHandler: ScrollHandler?
    
    open lazy var tableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: style)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        return tableView
    }()
    
    open var style: UITableView.Style = .grouped
    
    open lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        return refreshControl
    }()
    open var enabledPullToRefresh: Bool = false {
        didSet {
            guard enabledPullToRefresh else {
                refreshControl.removeFromSuperview()
                return
            }
            tableView.addSubview(refreshControl)
        }
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    /// 下拉刷新
    @objc
    open func pullToRefresh() {}
}

// MARK: - Table

extension TableController: UITableViewDataSource {
    open func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}

extension TableController: UITableViewDelegate {
    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    open func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    open func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Scroll

extension TableController: UIScrollViewDelegate {
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollHandler?(.didScroll(scrollView))
    }
    
    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollHandler?(.beginDragging(scrollView))
    }
    open func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        scrollHandler?(.willEndDragging(scrollView, velocity, targetContentOffset))
    }
    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollHandler?(.didEndDragging(scrollView, decelerate))
    }
    
    open func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        scrollHandler?(.beginDragging(scrollView))
    }
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollHandler?(.endDecelerating(scrollView))
    }
}

public extension ScrollViewStatus {
    var scrollView: UIScrollView {
        switch self {
        case .didScroll(let scrollView): return scrollView
            
        case .beginDragging(let scrollView): return scrollView
        case .willEndDragging(let scrollView, _, _): return scrollView
        case .didEndDragging(let scrollView, _): return scrollView
        
        case .beginDecelerating(let scrollView): return scrollView
        case .endDecelerating(let scrollView): return scrollView
        }
    }
    
    /// 滚动状态
    enum ScrollStatus {
        /// 其它状态
        case normal
        
        /// 拖拽中
        case dragging
        /// 滚动停止 (无减速停止 || 减速之后停止)
        case scrollEnd
    }
    /// 滚动状态
    var scrollStatus: ScrollStatus {
        switch self {
        case .didScroll(let scrollView):
            guard scrollView.isDragging, scrollView.isTracking else { return .normal }
            return .dragging
        case let .didEndDragging(_, decelerate):
            guard !decelerate else { return .normal }
            return .scrollEnd
        case .endDecelerating:
            return .scrollEnd
        default: return .normal
        }
    }
}
