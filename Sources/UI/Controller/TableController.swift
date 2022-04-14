//
//  TableController.swift
//  Ext
//
//  Created by naijoug on 2020/5/27.
//

import UIKit

// MARK: - Unknown Cell (for placeholder)

public class UnknownCell: ExtTableCell {
    
    private var placeholderView: UIView!
    
    public override func setupUI() {
        super.setupUI()
        backgroundColor = .clear
        placeholderView = contentView.ext.add(UIView())
        
        placeholderView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            placeholderView.heightAnchor.constraint(equalToConstant: 1),
            placeholderView.topAnchor.constraint(equalTo: contentView.topAnchor),
            placeholderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            placeholderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            placeholderView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
}

// MARK: - Table Controller

open class TableController: BaseScrollController {
    
    open override var scrollView: UIScrollView { tableView }
    
    open private(set) lazy var tableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: style)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.ext.registerClass(UnknownCell.self)
        tableView.tableFooterView = UIView()
        self.configTable(tableView)
        return tableView
    }()
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        
        layoutTable()
    }
}

// MARK: - Override

extension TableController {
    
    /// tableView 风格 (默认: grouped)
    @objc
    open var style: UITableView.Style { .grouped }
    
    /// 配置 TableView
    @objc
    open func configTable(_ tableView: UITableView) {}
    
    /// 布局 TableView
    @objc
    open func layoutTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
}

// MARK: - Table

extension TableController: UITableViewDataSource {
    open func numberOfSections(in tableView: UITableView) -> Int { 1 }
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 0 }
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.ext.dequeueReusableCell(UnknownCell.self, for: indexPath)
    }
}

extension TableController: UITableViewDelegate {
    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { UITableView.automaticDimension }
    
    open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { CGFloat.leastNormalMagnitude }
    open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? { nil }
    
    open func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { CGFloat.leastNormalMagnitude }
    open func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? { nil }
    
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
