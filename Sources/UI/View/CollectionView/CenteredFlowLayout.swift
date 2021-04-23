//
//  CenteredFlowLayout.swift
//  Ext
//
//  Created by naijoug on 2021/3/19.
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

open class CenteredFlowLayout: UICollectionViewFlowLayout {
    var delegate: UICollectionViewDelegateFlowLayout? {
        return self.collectionView?.delegate as? UICollectionViewDelegateFlowLayout
    }
    
    /**
     Reference:
        - https://stackoverflow.com/questions/13492037
     */
    
    open override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        //Ext.debug("\(proposedContentOffset) | velocity: \(velocity)")
        guard let collectionView = self.collectionView,
            let attris = layoutAttributesForElements(in: collectionView.bounds),
            attris.count > 0 else {
                return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
        }
        var size = itemSize
        if let itemSize = delegate?.collectionView?(collectionView, layout: self, sizeForItemAt: IndexPath(item: 0, section: 0)) {
            //Ext.debug("delegate.itemSize: \(itemSize)")
            size = itemSize
        }
        let pageWidth = size.width + minimumLineSpacing
        //Ext.debug("pageWidth: \(pageWidth) | \(itemSize) | \(size)")
        var offsetX = pageWidth/2
        if abs(velocity.x) > 0.3 {
            offsetX += (velocity.x > 0) ? pageWidth : -pageWidth
        }
        let proposedContentOffsetCenterX = proposedContentOffset.x + offsetX
        var targetAttri = attris[0]
        for i in 1..<attris.count {
            let attri = attris[i]
            if attri.representedElementCategory != .cell { continue }
            let offset1 = abs(attri.center.x - proposedContentOffsetCenterX)
            let offset2 = abs(targetAttri.center.x - proposedContentOffsetCenterX)
            //Ext.debug("attri centerX: \(attri.center.x) | \(targetAttri.center.x) | \(offset1) | \(offset2)")
            if offset1 < offset2 {
                //Ext.debug("taregt changed.")
                targetAttri = attri
            }
        }
        let targetX = targetAttri.center.x - collectionView.bounds.width/2
        //Ext.debug("targetX: \(targetX) \(targetAttri.center.x)")
        return CGPoint(x: targetX, y: proposedContentOffset.y)
    }
}

/// 可分页布局
open class PageableFlowLayout: UICollectionViewFlowLayout {
    var delegate: UICollectionViewDelegateFlowLayout? {
        return self.collectionView?.delegate as? UICollectionViewDelegateFlowLayout
    }
    
    private var logEnabled: Bool { false }
    
    /**
     Reference:
        - https://stackoverflow.com/questions/13492037
     */
    
    open override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        Ext.debug("\(proposedContentOffset) | velocity: \(velocity)", logEnabled: logEnabled)
        guard let collectionView = self.collectionView,
            let attris = layoutAttributesForElements(in: collectionView.bounds),
            attris.count > 0 else {
                return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
        }
        var size = itemSize
        if let itemSize = delegate?.collectionView?(collectionView, layout: self, sizeForItemAt: IndexPath(item: 0, section: 0)) {
            Ext.debug("delegate.itemSize: \(itemSize)", logEnabled: logEnabled)
            size = itemSize
        }
        let pageWidth = size.width + minimumLineSpacing
        Ext.debug("pageWidth: \(pageWidth) | \(itemSize) | \(size)", logEnabled: logEnabled)
        var offsetX = pageWidth/2
        if abs(velocity.x) > 0.3 {
            offsetX += (velocity.x > 0) ? pageWidth : -pageWidth
        }
        let proposedContentOffsetCenterX = proposedContentOffset.x + offsetX
        var targetAttri = attris[0]
        for i in 1..<attris.count {
            let attri = attris[i]
            if attri.representedElementCategory != .cell { continue }
            let offset1 = abs(attri.center.x - proposedContentOffsetCenterX)
            let offset2 = abs(targetAttri.center.x - proposedContentOffsetCenterX)
            Ext.debug("attri centerX: \(attri.center.x) | \(targetAttri.center.x) | \(offset1) | \(offset2)", logEnabled: logEnabled)
            if offset1 < offset2 {
                Ext.debug("taregt changed.", logEnabled: logEnabled)
                targetAttri = attri
            }
        }
        let targetX = targetAttri.center.x - collectionView.bounds.width/2 + size.width/4
        Ext.debug("targetX: \(targetX) \(targetAttri.center.x)", logEnabled: logEnabled)
        return CGPoint(x: targetX, y: proposedContentOffset.y)
    }
}
