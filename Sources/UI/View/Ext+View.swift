//
//  Ext+View.swift
//  Ext
//
//  Created by naijoug on 2021/3/19.
//

import UIKit

/// 自定义视图
open class View: UIView {
    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    /// 初始化视图
    @objc
    open func setupUI() { }
}

/// 自定义控件
open class Control: UIControl {
    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    /// 初始化 UI
    @objc
    open func setupUI() { }
}

/// 自定义 TableViewCell (基类)
open class TableCell: UITableViewCell {
    @available(*, unavailable)
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    /// 初始化 UI
    @objc
    open func setupUI() { }
}
/// 自定义 TableHeaderFooterView (基类)
open class TableHeaderFooterView: UITableViewHeaderFooterView {
    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    /// 初始化 UI
    @objc
    open func setupUI() { }
}

/// 自定义 CollectionViewCell (基类)
open class CollectionCell: UICollectionViewCell {
    @available(*, unavailable)
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    /// 初始化 UI
    @objc
    open func setupUI() { }
}

open class CollectionReusableView: UICollectionReusableView {
    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    /// 初始化 UI
    @objc
    open func setupUI() { }
}


// MARK: - Wrapper

public extension Ext {
    
    class WrapperTableCell<T: UIView>: TableCell {
        public private(set) var wrapperView: T!
        
        open override func setupUI() {
            super.setupUI()
            
            wrapperView = contentView.ext.add(T())
            wrapperView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                wrapperView.topAnchor.constraint(equalTo: contentView.topAnchor),
                wrapperView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
                wrapperView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
                wrapperView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
        }
    }

    class WrapperCollectionCell<T: UIView>: CollectionCell {
        public private(set) var wrapperView: T!
        
        open override func setupUI() {
            super.setupUI()
            
            wrapperView = contentView.ext.add(T())
            wrapperView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                wrapperView.topAnchor.constraint(equalTo: contentView.topAnchor),
                wrapperView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
                wrapperView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
                wrapperView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
        }
    }

    class WrapperCollectionReusableView<T: UIView>: CollectionReusableView {
        public private(set) var wrapperView: T!
        
        open override func setupUI() {
            super.setupUI()
            
            wrapperView = ext.add(T())
            wrapperView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                wrapperView.topAnchor.constraint(equalTo: self.topAnchor),
                wrapperView.leftAnchor.constraint(equalTo: self.leftAnchor),
                wrapperView.rightAnchor.constraint(equalTo: self.rightAnchor),
                wrapperView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
            ])
        }
    }
}
