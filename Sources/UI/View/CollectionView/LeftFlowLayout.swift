//
//  LeftFlowLayout.swift
//  Ext
//
//  Created by naijoug on 2021/3/19.
//

import UIKit

open class LeftFlowLayout: RTLFlowLayout {
    var delegate: UICollectionViewDelegateFlowLayout? {
        self.collectionView?.delegate as? UICollectionViewDelegateFlowLayout
    }
    
    open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let originalAttributes = super.layoutAttributesForElements(in: rect) else { return nil }
        var updatedAttributes = [UICollectionViewLayoutAttributes]()
        originalAttributes.forEach { (attri) in
            guard attri.representedElementKind == nil else {
                updatedAttributes.append(attri)
                return
            }
            if let updatedAttri = layoutAttributesForItem(at: attri.indexPath) {
                updatedAttributes.append(updatedAttri)
            }
        }
        return updatedAttributes
    }
    
    open override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        /**
         Reference :
            - copy -> fix error  "Logging only once for UICollectionViewFlowLayout cache mismatched frame
                                This is likely occurring because the flow layout subclass Ext.LeftFlowLayout is modifying attributes returned by UICollectionViewFlowLayout without copying them"
            - https://github.com/mokagio/UICollectionViewLeftAlignedLayout/issues/4
         */
        guard let currentItemAttributes = super.layoutAttributesForItem(at: indexPath)?.copy() as? UICollectionViewLayoutAttributes else { return nil }
        guard let collectionView = collectionView else { return nil }
        
        let sectionInset = delegate?.collectionView?(collectionView, layout: self, insetForSectionAt: indexPath.section) ?? self.sectionInset
        
        let isFirstItemInSection = indexPath.item == 0
        
        guard !isFirstItemInSection else {
            // is the first item : align left to the insert left
            currentItemAttributes.alignLeftFrameWithSectionInset(sectionInset)
            return currentItemAttributes
        }
        
        let previousFrame = layoutAttributesForItem(at: IndexPath(item: indexPath.item - 1, section: indexPath.section))?.frame ?? CGRect.zero
        let currentFrame = currentItemAttributes.frame
        
        let layoutWidth = collectionView.frame.size.width - sectionInset.left - sectionInset.right
        let strecthedCurrentFrame = CGRect(x: sectionInset.left, y: currentFrame.origin.y, width: layoutWidth, height: currentFrame.size.height)
        
        let isFirstItemInRow = !previousFrame.intersects(strecthedCurrentFrame)
        
        guard !isFirstItemInRow else {
            // is the first in row : align left to the insert left
            currentItemAttributes.alignLeftFrameWithSectionInset(sectionInset)
            return currentItemAttributes
        }
        
        let interitemSpacing = delegate?.collectionView?(collectionView, layout: self, minimumInteritemSpacingForSectionAt: indexPath.section) ?? minimumInteritemSpacing
        var frame = currentItemAttributes.frame
        frame.origin.x = previousFrame.origin.x + previousFrame.size.width + interitemSpacing
        currentItemAttributes.frame = frame
        return currentItemAttributes
    }
}

extension UICollectionViewLayoutAttributes {
    func alignLeftFrameWithSectionInset(_ sectionInset: UIEdgeInsets) {
        var frame = self.frame
        frame.origin.x = sectionInset.left
        self.frame = frame
    }
}
