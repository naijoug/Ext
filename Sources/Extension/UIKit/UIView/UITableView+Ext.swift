//
//  UITableView+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/28.
//

import UIKit

public extension ExtWrapper where Base: UITableView {
    /// 注册 Nib Cell
    func registerNib<T>(_ cellType: T.Type) where T: UITableViewCell {
        base.register(cellType.ext.nib, forCellReuseIdentifier: cellType.ext.identifier)
    }
    /// 注册自定义 Cell
    func registerClass<T>(_ cellType: T.Type) where T: UITableViewCell {
        base.register(cellType, forCellReuseIdentifier: cellType.ext.identifier)
    }
    
    /// 从缓存池中取出 Cell
    func dequeueReusableCell<T>(_ cellType: T.Type) -> T where T: UITableViewCell {
        base.dequeueReusableCell(withIdentifier: cellType.ext.identifier) as! T
    }
    /// 从缓存池中取出 Cell
    func dequeueReusableCell<T>(_ cellType: T.Type, for indexPath: IndexPath) -> T where T: UITableViewCell {
        base.dequeueReusableCell(withIdentifier: cellType.ext.identifier, for: indexPath) as! T
    }
    
    /// 注册自定义 HeaderFooterView
    func registerHeaderFooterView<T>(_ type: T.Type) where T: UITableViewHeaderFooterView {
        base.register(type, forHeaderFooterViewReuseIdentifier: type.ext.identifier)
    }
    /// 从缓存池中取出 HeaderFooterView
    func dequeueHeaderFooterView<T>(_ type: T.Type) -> T where T: UITableViewHeaderFooterView {
        base.dequeueReusableHeaderFooterView(withIdentifier: type.ext.identifier) as! T
    }
}

public extension ExtWrapper where Base: UITableView {
    
    // Reference: https://stackoverflow.com/questions/34661793/setting-tableheaderview-height-dynamically
    
    /// 刷新 headerView 高度
    func reloadHeaderViewHeight() {
        guard let headerView = base.tableHeaderView else { return }
        
        let height = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        var headerFrame = headerView.frame
        
        // Comparison necessary to avoid infinite loop
        guard height != headerFrame.size.height else { return }
        
        headerFrame.size.height = height
        headerView.frame = headerFrame
        base.tableHeaderView = headerView
    }
     
    // Reference: http://www.codeido.com/2018/02/dynamic-uitableview-header-view-height-using-auto-layout/
    
    /// 布局 headerView
    func layoutHeaderView() {
     
        guard let headerView = base.tableHeaderView else { return }
        headerView.translatesAutoresizingMaskIntoConstraints = false
     
        let headerWidth = headerView.bounds.size.width
        let temporaryWidthConstraints = NSLayoutConstraint.constraints(
            withVisualFormat: "[headerView(width)]",
            options: NSLayoutConstraint.FormatOptions(rawValue: UInt(0)),
            metrics: ["width": headerWidth],
            views: ["headerView": headerView])
     
        headerView.addConstraints(temporaryWidthConstraints)
     
        headerView.setNeedsLayout()
        headerView.layoutIfNeeded()
     
        let headerSize = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        let height = headerSize.height
        var frame = headerView.frame
     
        Ext.debug("layout before")
        
        guard height != frame.size.height else { return }
        
        Ext.debug("layout after")
        
        frame.size.height = height
        headerView.frame = frame
     
        base.tableHeaderView = headerView
        
        headerView.removeConstraints(temporaryWidthConstraints)
        headerView.translatesAutoresizingMaskIntoConstraints = true
    }
    
    /**
     Reference:
        - https://stackoverflow.com/questions/48017955/ios-tableview-reload-and-scroll-top/50029233
     */
    
    /// 刷新列表
    func reloadData(_ completion: @escaping Ext.VoidHandler) {
        UIView.animate(withDuration: 0, animations: {
            base.reloadData()
        }, completion:{ _ in
            completion()
        })
    }
    
    /// 刷新数据 & 滚动到最底部
    func reloadDataToBottom(_ animated: Bool = true) {
        UIView.animate(withDuration: 0, animations: {
            base.reloadData()
        }, completion:{ _ in
            scrollTo(.bottom, animated: animated)
        })
    }
    
    
    enum Position {
        case top
        case bottom
    }
    
    func scrollTo(_ postion: Position, animated: Bool = true) {
        DispatchQueue.main.asyncAfter(deadline: animated ? (.now() + .milliseconds(300)) : .now()) {
            let numberOfSections = base.numberOfSections
            guard numberOfSections > 0 else { return }
            switch postion {
            case .top:
                let numberOfRows = base.numberOfRows(inSection: 0)
                guard numberOfRows > 0 else {
                    base.scrollToRow(at: IndexPath(row: NSNotFound, section: 0), at: .top, animated: animated)
                    return
                }
                base.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: animated)
            case .bottom:
                let numberOfRows = base.numberOfRows(inSection: numberOfSections - 1)
                guard numberOfRows > 0 else { return }
                base.scrollToRow(at: IndexPath(row: numberOfRows - 1, section: numberOfSections - 1), at: .bottom, animated: animated)
            }
        }
    }
}
