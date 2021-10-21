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
 */

/// 自适应尺寸 UICollectionView
public class AutoSizedCollectionView: UICollectionView {

    public override var contentSize: CGSize {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    public override func reloadData() {
        super.reloadData()
        invalidateIntrinsicContentSize()
        layoutIfNeeded()
    }

    public override var intrinsicContentSize: CGSize {
////        return contentSize
//        return self.collectionViewLayout.collectionViewContentSize
        layoutIfNeeded()
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
}

public class AutoSizedTableView: UITableView {
    
    public override var contentSize: CGSize {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
//    public override func reloadData() {
//        super.reloadData()
//        invalidateIntrinsicContentSize()
//    }

    public override var intrinsicContentSize: CGSize {
        layoutIfNeeded()
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
}
