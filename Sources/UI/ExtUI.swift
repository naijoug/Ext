//
//  ExtUI.swift
//  Ext
//
//  Created by guojian on 2021/8/11.
//

import UIKit

// MARK: - Ext UI

public extension Ext {
    /// Ext UI Module
    enum UI {}
}

extension Ext.UI {
    
    /// 自定义视图
    open class View: UIView {
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
    open class Control: UIControl {
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
    open class ImageView: UIImageView {
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

    // MARK: Cell

    /// 自定义 TableViewCell (基类)
    open class TableCell: UITableViewCell {
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
    open class TableHeaderFooterView: UITableViewHeaderFooterView {
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
    open class CollectionCell: UICollectionViewCell {
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
    open class CollectionReusableView: UICollectionReusableView {
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
    
}

// MARK: - Ext UI Wrapper

public extension Ext.UI {
    /// Ext UI Wrapper Module
    enum Wrapper {}
}

extension Ext.UI.Wrapper {
    
    open class TableCell<T: UIView>: Ext.UI.TableCell {
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

    open class TableHeaderFooterView<T: UIView>: Ext.UI.TableHeaderFooterView {
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
    
    open class CollectionCell<T: UIView>: Ext.UI.CollectionCell {
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

    open class CollectionReusableView<T: UIView>: Ext.UI.CollectionReusableView {
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
