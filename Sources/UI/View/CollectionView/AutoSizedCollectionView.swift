//
//  AutoSizedCollectionView.swift
//  Ext
//
//  Created by guojian on 2021/10/8.
//

import UIKit

/// 自适应尺寸 UICollectionView
public class AutoSizedCollectionView: UICollectionView {

    // Reference: https://stackoverflow.com/questions/42437966/how-to-adjust-height-of-uicollectionview-to-be-the-height-of-the-content-size-of
    
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
