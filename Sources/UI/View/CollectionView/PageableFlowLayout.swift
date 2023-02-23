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
public class PageableFlowLayout: RTLFlowLayout, ExtLogable {
    public var logEnabled: Bool = false
    
    public enum Alignment {
        case left
        case center
        case right
    }
    
    /// 对齐方式 (默认: 居中对齐)
    public var alignment: Alignment = .center
    
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
        ext.log("\(proposedContentOffset) | velocity: \(velocity)")
        guard let collectionView = self.collectionView,
              let attris = layoutAttributesForElements(in: collectionView.bounds), attris.count > 0 else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
        }
        
        ext.log("ext: \(ext.pageWidth) | itemSize: \(ext.itemSize) | lineSpacing \(ext.minimumLineSpacing) | interitemSpacing \(ext.minimumInteritemSpacing)")
        
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
            ext.log("attri centerX: \(attri.center.x) | \(targetAttri.center.x) | offset: \(offset1) - \(offset2)")
            if offset1 < offset2 {
                ext.log("taregt changed.")
                targetAttri = attri
            }
        }
        var targetX = targetAttri.center.x
        switch alignment {
        case .left:     targetX -= (ext.itemSize.width/2 + ext.minimumLineSpacing)
        case .center:   targetX -= collectionView.bounds.width/2
        case .right:    targetX += ext.minimumLineSpacing
        }
        ext.log("targetX: \(targetAttri.center.x) -> \(targetX) | \(ext.itemSize.width/4)")
        return CGPoint(x: targetX, y: proposedContentOffset.y)
    }
}
