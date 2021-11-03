//
//  CenteredFlowLayout.swift
//  Ext
//
//  Created by naijoug on 2021/3/19.
//

import UIKit

public class CenteredFlowLayout: UICollectionViewFlowLayout {
    
    /**
     Reference:
        - https://stackoverflow.com/questions/13492037
     */
    
    open override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        //Ext.debug("\(proposedContentOffset) | velocity: \(velocity)")
        guard let collectionView = self.collectionView,
              let attris = layoutAttributesForElements(in: collectionView.bounds), attris.count > 0 else {
                  return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
        }
        
        var offsetX = ext.pageWidth/2
        if abs(velocity.x) > 0.3 {
            offsetX += ((velocity.x > 0) ? 1 : -1) * ext.pageWidth
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
