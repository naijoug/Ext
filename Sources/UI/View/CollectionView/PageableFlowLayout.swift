//
//  PageableFlowLayout.swift
//  Ext
//
//  Created by guojian on 2021/10/8.
//

import UIKit

extension ExtWrapper where Base: UICollectionViewFlowLayout {
    
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

/// 可分页布局
public class PageableFlowLayout: UICollectionViewFlowLayout {
    
    public var logEnabled: Bool = true
    
    /**
     Reference:
        - https://stackoverflow.com/questions/13492037
     */
    
    open override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        Ext.debug("\(proposedContentOffset) | velocity: \(velocity)", logEnabled: logEnabled)
        guard let collectionView = self.collectionView,
              let attris = layoutAttributesForElements(in: collectionView.bounds), attris.count > 0 else {
                  return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
        }
        
        Ext.debug("ext: \(ext.pageWidth) | itemSize: \(ext.itemSize) | lineSpacing \(ext.minimumLineSpacing) | interitemSpacing \(ext.minimumInteritemSpacing)", logEnabled: logEnabled)
        
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
            Ext.debug("attri centerX: \(attri.center.x) | \(targetAttri.center.x) | offset: \(offset1) - \(offset2)", logEnabled: logEnabled)
            if offset1 < offset2 {
                Ext.debug("taregt changed.", logEnabled: logEnabled)
                targetAttri = attri
            }
        }
        let targetX = targetAttri.center.x - ext.itemSize.width/2 - ext.minimumLineSpacing
        Ext.debug("targetX: \(targetX) \(targetAttri.center.x) | \(ext.itemSize.width/4)", logEnabled: logEnabled)
        return CGPoint(x: targetX, y: proposedContentOffset.y)
    }
}
