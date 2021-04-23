//
//  Ext+View.swift
//  Ext
//
//  Created by naijoug on 2021/3/19.
//

import UIKit

// MARK: - 自定义视图

/// 自定义视图
open class ExtView: UIView {
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    /// 初始化视图
    @objc open func setupView() {}
}

/// 自定义控件
open class ExtControl: UIControl {
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    /// 初始化视图
    @objc open func setupView() {}
}

/// 自定义按钮 (基类)
open class ExtButton: UIButton {
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    /// 初始化按钮
    @objc open func setupButton() {}
}

/// 自定义图片
open class ExtImageView: UIImageView {
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    public override init(image: UIImage?) {
        super.init(image: image)
        setupView()
    }
    public init() {
        super.init(image: nil)
        setupView()
    }
    /// 初始化视图
    @objc open func setupView() {}
}

// MARK: - Cell

/// 自定义 TableViewCell (基类)
open class ExtTableCell: UITableViewCell {
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    /// 初始化 Cell
    @objc open func setupCell() {}
}
/// 自定义 TableHeaderFooterView (基类)
open class ExtTableHeaderFooterView: UITableViewHeaderFooterView {
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupView()
    }
    /// 初始化视图
    @objc open func setupView() {}
}

/// 自定义 CollectionViewCell (基类)
open class ExtCollectionCell: UICollectionViewCell {
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }
    /// 初始化 Cell
    @objc open func setupCell() {}
}

open class ExtCollectionReusableView: UICollectionReusableView {
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    /// 初始化视图
    @objc open func setupView() {}
}

// MARK: - Wrapper

open class WrapperTableCell<T: UIView>: ExtTableCell {
    public private(set) var wrapperView: T!
    
    open override func setupCell() {
        super.setupCell()
        
        wrapperView = contentView.ext.add(T())
        wrapperView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            wrapperView.topAnchor.constraint(equalTo: contentView.topAnchor),
            wrapperView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            wrapperView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            wrapperView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
}

open class WrapperCollectionCell<T: UIView>: ExtCollectionCell {
    public private(set) var wrapperView: T!
    
    open override func setupCell() {
        super.setupCell()
        
        wrapperView = contentView.ext.add(T())
        wrapperView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            wrapperView.topAnchor.constraint(equalTo: contentView.topAnchor),
            wrapperView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            wrapperView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            wrapperView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
}

open class WrapperCollectionReusableView<T: UIView>: ExtCollectionReusableView {
    public private(set) var wrapperView: T!
    
    open override func setupView() {
        super.setupView()
        
        wrapperView = ext.add(T())
        wrapperView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            wrapperView.topAnchor.constraint(equalTo: self.topAnchor),
            wrapperView.leftAnchor.constraint(equalTo: self.leftAnchor),
            wrapperView.rightAnchor.constraint(equalTo: self.rightAnchor),
            wrapperView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])
    }
}
