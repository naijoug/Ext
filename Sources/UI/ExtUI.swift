//
//  ExtUI.swift
//  Ext
//
//  Created by guojian on 2021/8/11.
//

import UIKit

// MARK: - View

/// 自定义视图
open class ExtView: UIView {
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    @objc
    open func setupUI() {}
}

/// 自定义控件
open class ExtControl: UIControl {
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    @objc
    open func setupUI() {}
}

/// 自定义图片
open class ExtImageView: UIImageView {
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    public override init(image: UIImage?) {
        super.init(image: image)
        setupUI()
    }
    public init() {
        super.init(image: nil)
        setupUI()
    }
    
    @objc
    open func setupUI() {}
}

// MARK: - Cell

/// 自定义 TableViewCell (基类)
open class ExtTableCell: UITableViewCell {
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    @objc
    open func setupUI() {}
}
/// 自定义 TableHeaderFooterView (基类)
open class ExtTableHeaderFooterView: UITableViewHeaderFooterView {
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    @objc
    open func setupUI() {}
}

/// 自定义 CollectionViewCell (基类)
open class ExtCollectionCell: UICollectionViewCell {
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    @objc
    open func setupUI() {}
}
/// 自定义 CollectionReusableView (基类)
open class ExtCollectionReusableView: UICollectionReusableView {
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    @objc
    open func setupUI() {}
}

// MARK: - Wrapper

extension Ext {
    
    open class WrapperTableCell<T: UIView>: ExtTableCell {
        public private(set) var wrapperView: T!
        
        open var wrapperInsets: UIEdgeInsets { .zero }
        
        open override func setupUI() {
            super.setupUI()
            
            wrapperView = contentView.ext.add(T())
            wrapperView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                wrapperView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: wrapperInsets.top),
                wrapperView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: wrapperInsets.left),
                wrapperView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -wrapperInsets.right),
                wrapperView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -wrapperInsets.bottom)
            ])
        }
    }

    open class WrapperTableHeaderFooterView<T: UIView>: ExtTableHeaderFooterView {
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
    
    open class WrapperCollectionCell<T: UIView>: ExtCollectionCell {
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

    open class WrapperCollectionReusableView<T: UIView>: ExtCollectionReusableView {
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
