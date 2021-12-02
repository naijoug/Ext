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

// MARK: - Unknown Cell (for placeholder)

public class UnknownCell: ExtTableCell {
    
    private var placeholderView: UIView!
    
    public override func setupUI() {
        super.setupUI()
        backgroundColor = .clear
        placeholderView = contentView.ext.add(UIView())
        
        placeholderView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            placeholderView.heightAnchor.constraint(equalToConstant: CGFloat.leastNormalMagnitude),
            placeholderView.topAnchor.constraint(equalTo: contentView.topAnchor),
            placeholderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            placeholderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            placeholderView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
}

// MARK: - Table Controller

open class TableController: UIViewController, ControllerScrollable {
    public var scrollHandler: ScrollHandler?
    
// MARK: - Status
    
    open var style: UITableView.Style = .grouped
    
    /// 下拉刷新是否可用
    open var pullToRefreshEnabled: Bool = false {
        didSet {
            guard pullToRefreshEnabled else {
                refreshControl.removeFromSuperview()
                return
            }
            tableView.addSubview(refreshControl)
        }
    }
    
// MARK: - UI
    
    open private(set) lazy var tableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: style)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.ext.registerClass(UnknownCell.self)
        tableView.tableFooterView = UIView()
        self.configTable(tableView)
        return tableView
    }()
    open private(set) lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        return refreshControl
    }()
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        
        layoutTable()
    }
}

// MARK: - Override

extension TableController {
    
    /// 配置 TableView
    @objc
    open func configTable(_ tableView: UITableView) {}
    
    /// 布局 TableView
    @objc
    open func layoutTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
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
        return tableView.ext.dequeueReusableCell(UnknownCell.self, for: indexPath)
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
    
//    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        /**
//         Solution:
//            - https://stackoverflow.com/questions/8603359/change-default-icon-for-moving-cells-in-uitableview
//         */
//
//        guard let reoderView = cell.subviews.first(where: { $0.description.contains("Reorder") }) else { return }
//        reoderView.frame = CGRect(x: cell.bounds.width - cell.bounds.height*2, y: 0,
//                                  width: cell.bounds.height*2, height: cell.bounds.height)
//        guard let moveImageView = reoderView.subviews.first(where: { $0 is UIImageView }) as? UIImageView else { return }
//        moveImageView.isHidden = true
//    }
    
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
