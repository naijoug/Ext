//
//  CenterAlignedFlowLayout.swift
//  Ext
//
//  Created by guojian on 2021/12/2.
//

import UIKit

/**
 Reference:
    - https://stackoverflow.com/questions/13588283/how-to-center-align-the-cells-of-a-uicollectionview
    - https://stackoverflow.com/questions/16544186/how-can-i-center-rows-in-uicollectionview
 */

/// 居中对齐布局
public class CenterAlignedFlowLayout: RTLFlowLayout {

    private var attrCache = [IndexPath: UICollectionViewLayoutAttributes]()

    public override func prepare() {
        attrCache = [:]
    }

    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var updatedAttributes = [UICollectionViewLayoutAttributes]()

        let sections = self.collectionView?.numberOfSections ?? 0
        var section = 0
        while section < sections {
            let items = self.collectionView?.numberOfItems(inSection: section) ?? 0
            var item = 0
            while item < items {
                let indexPath = IndexPath(row: item, section: section)

                if let attributes = layoutAttributesForItem(at: indexPath), attributes.frame.intersects(rect) {
                    updatedAttributes.append(attributes)
                }

                let headerKind = UICollectionView.elementKindSectionHeader
                if let headerAttributes = layoutAttributesForSupplementaryView(ofKind: headerKind, at: indexPath) {
                    updatedAttributes.append(headerAttributes)
                }

                let footerKind = UICollectionView.elementKindSectionFooter
                if let footerAttributes = layoutAttributesForSupplementaryView(ofKind: footerKind, at: indexPath) {
                    updatedAttributes.append(footerAttributes)
                }

                item += 1
            }

            section += 1
        }

        return updatedAttributes
    }

    public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if let attributes = attrCache[indexPath] {
            return attributes
        }

        // Find the other items in the same "row"
        var rowBuddies = [UICollectionViewLayoutAttributes]()

        // Calculate the available width to center stuff within
        // sectionInset is NOT applicable here because a) we're centering stuff
        // and b) Flow layout has arranged the cells to respect the inset. We're
        // just hijacking the X position.
        var collectionViewWidth: CGFloat = 0
        if let collectionView = collectionView {
            collectionViewWidth = collectionView.bounds.width - collectionView.contentInset.left
                    - collectionView.contentInset.right
        }

        // To find other items in the "row", we need a rect to check intersects against.
        // Take the item attributes frame (from vanilla flow layout), and stretch it out
        var rowTestFrame: CGRect = super.layoutAttributesForItem(at: indexPath)?.frame ?? .zero
        rowTestFrame.origin.x = 0
        rowTestFrame.size.width = collectionViewWidth

        let totalRows = self.collectionView?.numberOfItems(inSection: indexPath.section) ?? 0

        // From this item, work backwards to find the first item in the row
        // Decrement the row index until a) we get to 0, b) we reach a previous row
        var rowStartIDX = indexPath.row
        while true {
            let prevIDX = rowStartIDX - 1

            if prevIDX < 0 {
                break
            }

            let prevPath = IndexPath(row: prevIDX, section: indexPath.section)
            let prevFrame: CGRect = super.layoutAttributesForItem(at: prevPath)?.frame ?? .zero

            // If the item intersects the test frame, it's in the same row
            if prevFrame.intersects(rowTestFrame) {
                rowStartIDX = prevIDX
            } else {
                // Found previous row, escape!
                break
            }
        }

        // Now, work back UP to find the last item in the row
        // For each item in the row, add it's attributes to rowBuddies
        var buddyIDX = rowStartIDX
        while true {
            if buddyIDX > totalRows - 1 {
                break
            }

            let buddyPath = IndexPath(row: buddyIDX, section: indexPath.section)

            if let buddyAttributes = super.layoutAttributesForItem(at: buddyPath),
               buddyAttributes.frame.intersects(rowTestFrame),
               let buddyAttributesCopy = buddyAttributes.copy() as? UICollectionViewLayoutAttributes {
                // If the item intersects the test frame, it's in the same row
                rowBuddies.append(buddyAttributesCopy)
                buddyIDX += 1
            } else {
                // Encountered next row
                break
            }
        }

        let flowDelegate = self.collectionView?.delegate as? UICollectionViewDelegateFlowLayout
        let selector = #selector(UICollectionViewDelegateFlowLayout.collectionView(_:layout:minimumInteritemSpacingForSectionAt:))
        let delegateSupportsInteritemSpacing = flowDelegate?.responds(to: selector) ?? false

        // x-x-x-x ... sum up the interim space
        var interitemSpacing = minimumInteritemSpacing

        // Check for minimumInteritemSpacingForSectionAtIndex support
        if let collectionView = collectionView, delegateSupportsInteritemSpacing && rowBuddies.count > 0 {
            interitemSpacing = flowDelegate?.collectionView?(collectionView,
                    layout: self,
                    minimumInteritemSpacingForSectionAt: indexPath.section) ?? 0
        }

        let aggregateInteritemSpacing = interitemSpacing * CGFloat(rowBuddies.count - 1)

        // Sum the width of all elements in the row
        var aggregateItemWidths: CGFloat = 0
        for itemAttributes in rowBuddies {
            aggregateItemWidths += itemAttributes.frame.width
        }

        // Build an alignment rect
        // |  |x-x-x-x|  |
        let alignmentWidth = aggregateItemWidths + aggregateInteritemSpacing
        let alignmentXOffset: CGFloat = (collectionViewWidth - alignmentWidth) / 2

        // Adjust each item's position to be centered
        var previousFrame: CGRect = .zero
        for itemAttributes in rowBuddies {
            var itemFrame = itemAttributes.frame

            if previousFrame.equalTo(.zero) {
                itemFrame.origin.x = alignmentXOffset
            } else {
                itemFrame.origin.x = previousFrame.maxX + interitemSpacing
            }

            itemAttributes.frame = itemFrame
            previousFrame = itemFrame

            // Finally, add it to the cache
            attrCache[itemAttributes.indexPath] = itemAttributes
        }

        return attrCache[indexPath]
    }
}
