//
//  UICollectionView+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/28.
//

import UIKit

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
        return base.dequeueReusableCell(withReuseIdentifier: cellType.ext.identifier, for: indexPath) as! T
    }
    
    func registerReusableHeaderView<T>(_ viewType: T.Type) where T: UICollectionReusableView {
        return registerReusableView(viewType, ofKind: UICollectionView.elementKindSectionHeader)
    }
    func registerReusableFooterView<T>(_ viewType: T.Type) where T: UICollectionReusableView {
        return registerReusableView(viewType, ofKind: UICollectionView.elementKindSectionFooter)
    }
    func registerReusableView<T>(_ viewType: T.Type, ofKind: String) where T: UICollectionReusableView {
        return base.register(viewType, forSupplementaryViewOfKind: ofKind, withReuseIdentifier: viewType.ext.identifier)
    }
    
    func dequeueReusableHeaderView<T>(_ viewType: T.Type, for indexPath: IndexPath) -> T where T: UICollectionReusableView {
        return dequeueReusableView(viewType, ofKind: UICollectionView.elementKindSectionHeader, for: indexPath)
    }
    func dequeueReusableFooterView<T>(_ viewType: T.Type, for indexPath: IndexPath) -> T where T: UICollectionReusableView {
        return dequeueReusableView(viewType, ofKind: UICollectionView.elementKindSectionFooter, for: indexPath)
    }
    func dequeueReusableView<T>(_ viewType: T.Type, ofKind: String, for indexPath: IndexPath) -> T where T: UICollectionReusableView {
        return base.dequeueReusableSupplementaryView(ofKind: ofKind, withReuseIdentifier: viewType.ext.identifier, for: indexPath) as! T
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
