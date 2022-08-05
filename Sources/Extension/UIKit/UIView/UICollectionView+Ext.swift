//
//  UICollectionView+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/28.
//

import UIKit

public extension ExtWrapper where Base: UICollectionViewFlowLayout {
    
    private var delegate: UICollectionViewDelegateFlowLayout? { base.collectionView?.delegate as? UICollectionViewDelegateFlowLayout }
    
    var itemSize: CGSize {
        guard let collectionView = base.collectionView,
              let size = delegate?.collectionView?(collectionView, layout: base, sizeForItemAt: IndexPath(item: 0, section: 0)) else {
                  return base.itemSize
              }
        return size
    }
    
    var minimumLineSpacing: CGFloat {
        guard let collectionView = base.collectionView,
              let spacing = delegate?.collectionView?(collectionView, layout: base, minimumLineSpacingForSectionAt: 0) else {
            return base.minimumLineSpacing
        }
        return spacing
    }
    
    var minimumInteritemSpacing: CGFloat {
        guard let collectionView = base.collectionView,
              let spacing = delegate?.collectionView?(collectionView, layout: base, minimumInteritemSpacingForSectionAt: 0) else {
            return base.minimumInteritemSpacing
        }
        return spacing
    }
    
    var pageWidth: CGFloat { itemSize.width + minimumLineSpacing }
}

public extension ExtWrapper where Base: UICollectionViewCell {
    /// 注册 Nib Cell
    static func registerNib(_ collectionView: UICollectionView) {
        collectionView.register(Base.ext.nib, forCellWithReuseIdentifier: Base.ext.identifier)
    }
    /// 注册自定义 Cell
    static func registerClass(_ collectionView: UICollectionView) {
        collectionView.register(Base.self, forCellWithReuseIdentifier: Base.ext.identifier)
    }
    
    /// 从缓存池中取出 Cell
    static func dequeueReusable(_ collectionView: UICollectionView, for indexPath: IndexPath) -> Base {
        collectionView.dequeueReusableCell(withReuseIdentifier: Base.ext.identifier, for: indexPath) as! Base
    }
}
public extension ExtWrapper where Base: UICollectionView {
    /// 注册 Nib Cell
    func registerNib<T>(_ cellType: T.Type) where T: UICollectionViewCell {
        base.register(cellType.ext.nib, forCellWithReuseIdentifier: cellType.ext.identifier)
    }
    /// 注册自定义 Cell
    func registerClass<T>(_ cellType: T.Type) where T: UICollectionViewCell {
        base.register(cellType, forCellWithReuseIdentifier: cellType.ext.identifier)
    }
    
    /// 从缓存池中取出 Cell
    func dequeueReusableCell<T>(_ cellType: T.Type, for indexPath: IndexPath) -> T where T: UICollectionViewCell {
        base.dequeueReusableCell(withReuseIdentifier: cellType.ext.identifier, for: indexPath) as! T
    }
}
public extension Ext {
    enum CollectionViewElementKindSection {
        /// UICollectionView header
        case header
        /// UICollectionView footer
        case footer
        
        fileprivate var uiKind: String {
            switch self {
            case .header: return UICollectionView.elementKindSectionHeader
            case .footer: return UICollectionView.elementKindSectionFooter
            }
        }
    }
}
public extension ExtWrapper where Base: UICollectionReusableView {
    /// 注册 UICollectionView header footer
    static func register(_ collectionView: UICollectionView, kind: Ext.CollectionViewElementKindSection) {
        collectionView.register(Base.self, forSupplementaryViewOfKind: kind.uiKind, withReuseIdentifier: Base.ext.identifier)
    }
    /// 从缓存池中取出 header footer
    static func dequeueReusable(_ collectionView: UICollectionView, kind: Ext.CollectionViewElementKindSection, for indexPath: IndexPath) -> Base {
        collectionView.dequeueReusableSupplementaryView(ofKind: kind.uiKind, withReuseIdentifier: Base.ext.identifier, for: indexPath) as! Base
    }
}
public extension ExtWrapper where Base: UICollectionView {
    /// 注册 UICollectionView header footer
    func registerReusableView<T>(_ viewType: T.Type, kind: Ext.CollectionViewElementKindSection) where T: UICollectionReusableView {
        base.register(viewType, forSupplementaryViewOfKind: kind.uiKind, withReuseIdentifier: viewType.ext.identifier)
    }
    /// 从缓存池中取出 header footer
    func dequeueReusableView<T>(_ viewType: T.Type, kind: Ext.CollectionViewElementKindSection, for indexPath: IndexPath) -> T where T: UICollectionReusableView {
        base.dequeueReusableSupplementaryView(ofKind: kind.uiKind, withReuseIdentifier: viewType.ext.identifier, for: indexPath) as! T
    }
}

public extension ExtWrapper where Base: UICollectionView {
    
    /// 刷新列表
    func reloadData(_ completion: @escaping Ext.VoidHandler) {
        UIView.animate(withDuration: 0, animations: {
            base.reloadData()
        }, completion:{ _ in
            completion()
        })
    }
    
}
