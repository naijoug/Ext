//
//  PageableFlowLayout.swift
//  Ext
//
//  Created by guojian on 2021/10/8.
//

import UIKit

/// 可分页布局
public class PageableFlowLayout: UICollectionViewFlowLayout {
    
    private var delegate: UICollectionViewDelegateFlowLayout? { collectionView?.delegate as? UICollectionViewDelegateFlowLayout }
    
    public var logEnabled: Bool = true
    
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
        Ext.debug("pageWidth: \(pageWidth) | itemSize: \(itemSize) | size: \(size)", logEnabled: logEnabled)
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
            Ext.debug("attri centerX: \(attri.center.x) | \(targetAttri.center.x) | offset: \(offset1) - \(offset2)", logEnabled: logEnabled)
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
