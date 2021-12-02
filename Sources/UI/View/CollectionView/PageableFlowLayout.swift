//
//  PageableFlowLayout.swift
//  Ext
//
//  Created by guojian on 2021/10/8.
//

import UIKit

/**
 Reference:
    - https://stackoverflow.com/questions/13492037
 */

/// 可分页布局
public class PageableFlowLayout: UICollectionViewFlowLayout {
    
    public enum Alignment {
        case left
        case center
        case right
    }
    
    /// 对齐方式 (默认: 居中对齐)
    public var alignment: Alignment = .center
    
    public var logEnabled: Bool = true
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    public override init() {
        super.init()
        scrollDirection = .horizontal
    }
    public convenience init(_ alignment: Alignment) {
        self.init()
        self.alignment = alignment
    }
    
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
        var targetX = targetAttri.center.x
        switch alignment {
        case .left:     targetX -= (ext.itemSize.width/2 + ext.minimumLineSpacing)
        case .center:   targetX -= collectionView.bounds.width/2
        case .right:    targetX += ext.minimumLineSpacing
        }
        Ext.debug("targetX: \(targetAttri.center.x) -> \(targetX) | \(ext.itemSize.width/4)", logEnabled: logEnabled)
        return CGPoint(x: targetX, y: proposedContentOffset.y)
    }
}
