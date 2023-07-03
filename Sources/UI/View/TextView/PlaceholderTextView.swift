//
//  PlaceholderTextView.swift
//  Ext
//
//  Created by naijoug on 2020/3/23.
//

import UIKit

/**
 Reference:
    - https://stackoverflow.com/questions/12591192/center-text-vertically-in-a-uitextview
    - https://stackoverflow.com/questions/7235310/uitextview-alignment-to-bottom
 */

open class PlaceholderTextView: UITextView {
    
//    public enum Alignment {
//        case top
//        case center
//        case bottom
//    }
//
//    /// 文本垂直对齐方式
//    public var textVerticalAlignment: Alignment = .top
//
//    public override var contentSize: CGSize {
//        didSet {
//            let height = bounds.size.height
//            let contentHeight = contentSize.height
//
//            var topCorrection: CGFloat = 0.0
//            switch textVerticalAlignment {
//            case .top: ()
//            case .center:
//                topCorrection = max(0, (height - contentHeight * zoomScale)/2.0)
//            case .bottom:
//                topCorrection = height - contentHeight
//            }
//
//            contentInset = UIEdgeInsets(top: topCorrection, left: 0, bottom: 0, right: 0)
//        }
//    }
    
    /// 占位符是否可用
    public var placeholderEnabled: Bool = true { didSet { setNeedsDisplay() } }
    /// 占位文字
    open var placeholder: String? { didSet { setNeedsDisplay() } }
    /// 占位字体
    open var placeholderFont: UIFont? { didSet { setNeedsDisplay() } }
    /// 占位颜色
    open var placeholderColor: UIColor = UIColor.lightGray { didSet { setNeedsDisplay() } }
    /// 占位文字偏移
    open var placeholderOffset: CGPoint = CGPoint(x: 5, y: 0) { didSet { setNeedsDisplay() } }
    
    open override var font: UIFont? { didSet { setNeedsDisplay() } }
    open override var text: String! { didSet { setNeedsDisplay() } }
    open override var textContainerInset: UIEdgeInsets { didSet { setNeedsDisplay() } }
    open override var attributedText: NSAttributedString! { didSet { setNeedsDisplay() } }
    
    public required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        
        NotificationCenter.default.addObserver(forName: UITextView.textDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            guard let `self` = self else { return }
            self.setNeedsDisplay()
        }
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }
    
    open override func draw(_ rect: CGRect) {
        guard placeholderEnabled, !hasText else { return }
        guard let placeholder = placeholder, !placeholder.isEmpty else { return }
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 3
        var offsetX: CGFloat = placeholderOffset.x
        let offsetY: CGFloat = placeholderOffset.y
        Ext.inner.ext.log("\(offsetX), \(offsetY)")
        (placeholder as NSString).draw(
            in: CGRect(x: offsetX + textContainerInset.left,
                       y: offsetY + textContainerInset.top,
                       width: rect.size.width - offsetX - textContainerInset.left - textContainerInset.right,
                       height: rect.size.height - offsetY - textContainerInset.top - textContainerInset.bottom),
            withAttributes: [
                .font: placeholderFont ?? (font ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)),
                .foregroundColor: placeholderColor,
                .paragraphStyle: style
            ]
        )
    }
}

public extension UITextView {
    
    /// 插入富文本
    /// - Parameters:
    ///   - attri: 富文本内容
    ///   - index: 指定位置 (nil: 表示在光标位置插入)
    func insert(_ attri: NSAttributedString, at index: Int? = nil) {
        let mAttri = NSMutableAttributedString(attributedString: self.attributedText)
        if let index = index {
            mAttri.insert(attri, at: index)
            
            if let font = self.font {
                mAttri.addAttributes([.font: font], range: NSRange(location: 0, length: mAttri.length))
            }
            self.attributedText = mAttri
        } else {
            // 当前光标输入位置
            let location = self.selectedRange.location
            var range = self.selectedRange
            if location - 1 >= 0 {
                let atRange = NSRange(location: location - 1, length: 1)
                if mAttri.attributedSubstring(from: atRange).string == "@" {
                    range = atRange
                }
            }
            mAttri.replaceCharacters(in: range, with: attri)
            
            if let font = self.font {
                mAttri.addAttributes([.font: font], range: NSRange(location: 0, length: mAttri.length))
            }
            self.attributedText = mAttri
            
            self.selectedRange = NSRange(location: range.location + attri.length, length: 0)
        }
    }
    
    /// 替换富文本
    func replace(_ attri: NSAttributedString, in range: NSRange) {
        // 当前光标位置
        let mAttri = attributedText?.ext.mutable ?? NSMutableAttributedString()
        mAttri.replaceCharacters(in: range, with: attri)
        self.attributedText = mAttri
        
        self.selectedRange = NSRange(location: range.location + attri.length, length: 0)
    }
}
