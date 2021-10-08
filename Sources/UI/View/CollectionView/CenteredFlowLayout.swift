//
//  CenteredFlowLayout.swift
//  Ext
//
//  Created by naijoug on 2021/3/19.
//

import UIKit

public class CenteredFlowLayout: UICollectionViewFlowLayout {
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
