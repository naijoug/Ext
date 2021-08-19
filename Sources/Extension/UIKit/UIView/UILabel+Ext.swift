//
//  UILabel+Ext.swift
//  Ext
//
//  Created by guojian on 2021/2/4.
//

import UIKit

public extension ExtWrapper where Base == UILabel {
    
    /** Reference:
        - https://stackoverflow.com/questions/1256887/create-tap-able-links-in-the-nsattributedstring-of-a-uilabel
        - https://www.codementor.io/@nguyentruongky/hyperlink-label-qv2k8rpk9
     */
    
    func isTap(_ gesture: UITapGestureRecognizer, target: String, in text: String) -> Bool {
        guard let attributedText = base.attributedText else { return false }
        
        let labelSize = base.bounds.size
        let textContainer   = NSTextContainer(size: labelSize)
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = base.lineBreakMode
        textContainer.maximumNumberOfLines = base.numberOfLines
        
        let layoutManager   = NSLayoutManager()
        let textStorage     = NSTextStorage(attributedString: attributedText)
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        let textContainerOffset = CGPoint(
            x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,
            y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y
        )
        let locationOfTouchInLabel = gesture.location(in: base)
        let locationOfTouchInTextContainer = CGPoint(
            x: locationOfTouchInLabel.x - textContainerOffset.x,
            y: locationOfTouchInLabel.y - textContainerOffset.y
        )
        let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        
        let targetRange = (text as NSString).range(of: target)
        return NSLocationInRange(indexOfCharacter, targetRange)
    }
}
