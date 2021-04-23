//
//  PlaceholderTextView.swift
//  Ext
//
//  Created by naijoug on 2020/3/23.
//

import UIKit

open class PlaceholderTextView: UITextView {
    
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
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        NotificationCenter.default.addObserver(self, selector: #selector(textChange), name: UITextView.textDidChangeNotification, object: nil)

    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc fileprivate func textChange() { setNeedsDisplay() }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }
    
    open override func draw(_ rect: CGRect) {
        guard !hasText else { return }
        guard let placeholder = placeholder, !placeholder.isEmpty else { return }
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 3
        let offsetX: CGFloat = placeholderOffset.x
        let offsetY: CGFloat = placeholderOffset.y
        (placeholder as NSString).draw(in: CGRect(x: textContainerInset.left + offsetX,
                                                  y: textContainerInset.top + offsetY,
                                                  width: rect.size.width - textContainerInset.left - offsetX - textContainerInset.right,
                                                  height: rect.size.height - textContainerInset.top - offsetY - textContainerInset.bottom),
                                        withAttributes: [NSAttributedString.Key.font: placeholderFont ?? (font ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)),
                                                         NSAttributedString.Key.foregroundColor: placeholderColor,
                                                         NSAttributedString.Key.paragraphStyle: style])
    }
    

}
