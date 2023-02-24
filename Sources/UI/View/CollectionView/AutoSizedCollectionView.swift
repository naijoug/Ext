//
//  AutoSizedCollectionView.swift
//  Ext
//
//  Created by guojian on 2021/10/8.
//

import UIKit

/**
 Reference:
    - https://stackoverflow.com/questions/42437966/how-to-adjust-height-of-uicollectionview-to-be-the-height-of-the-content-size-of
    - https://stackoverflow.com/questions/56318626/dynamic-height-uicollectionview-inside-a-dynamic-height-uitableviewcell
    - https://stackoverflow.com/questions/24126708/uicollectionview-inside-a-uitableviewcell-dynamic-height
    - https://stackoverflow.com/questions/25895311/uicollectionview-self-sizing-cells-with-auto-layout
    - https://medium.com/@rozan.ktm/uicollectionview-inside-uitableviewcell-dynamic-height-based-on-uicollectionviewcell-height-86b3257e85c6
 */

/// 自适应尺寸 UICollectionView
public class AutoSizedCollectionView: UICollectionView {
    
    public override var intrinsicContentSize: CGSize {
        collectionViewLayout.collectionViewContentSize
    }
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        Ext.inner.ext.log("\(bounds) | \(collectionViewLayout.collectionViewContentSize)")
        guard bounds.size != intrinsicContentSize else { return }
        invalidateIntrinsicContentSize()
    }
    
    public override func reloadData() {
        super.reloadData()
        
        invalidateIntrinsicContentSize()
        setNeedsLayout()
        layoutIfNeeded()
    }
    
}

public class AutoSizedTableView: UITableView {
    
    public override var contentSize: CGSize {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    public override var intrinsicContentSize: CGSize {
        layoutIfNeeded()
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
}
