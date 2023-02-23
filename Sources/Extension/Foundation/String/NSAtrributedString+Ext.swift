//
//  NSAttributedString+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/28.
//

import Foundation

public extension ExtWrapper where Base: NSAttributedString {
    /// 整个富文本串 range
    var rangOfAll: NSRange { NSRange(location: 0, length: base.length) }
    
    /// 可变的富文本
    var mutable: NSMutableAttributedString { NSMutableAttributedString(attributedString: base) }
}

public extension ExtWrapper where Base: NSAttributedString {
    /// 遍历富文本
    func enumerate(in range: NSRange? = nil, handler: ([NSAttributedString.Key : Any], NSRange, UnsafeMutablePointer<ObjCBool>) -> Void) {
        base.enumerateAttributes(in: range ?? base.ext.rangOfAll, options: []) { attri, range, stop in
            handler(attri, range, stop)
        }
    }
    
    /// 解码富文本附件
    func decodeAttachments() -> [Any] {
        var items = [Any]()
        enumerate { attri, _, _ in
            guard let attachment = attri[.attachment] else { return }
            items.append(attachment)
        }
        return items
    }
}

public extension ExtWrapper where Base: NSAttributedString {
    
    /// 富文本拼接
    /// - Parameter attris: 富文本数组
    /// - Parameter space: 富文本之间是否加入空格(默认: false)
    static func attris(_ attris: [NSAttributedString?], space: Bool = false) -> NSAttributedString {
        let items = attris.compactMap({ $0 })
        let mAttri = NSMutableAttributedString()
        for i in 0..<items.count {
            if space, i != 0 {
                mAttri.append(NSAttributedString.ext.text(" ", font: UIFont.systemFont(ofSize: 11), color: .clear))
            }
            mAttri.append(items[i])
        }
        return mAttri
    }
    
    /// 富文本文字
    /// - Parameters:
    ///   - text: 文字内容
    ///   - font: 字体
    ///   - color: 字体颜色
    ///   - underline: 是否有下划线
    static func text(_ text: String, font: UIFont, color: UIColor,
                     underline: Bool = false) -> NSAttributedString {
        var attrs = [NSAttributedString.Key : Any]()
        attrs[.font] = font
        attrs[.foregroundColor] = color
        if underline {
            attrs[.underlineStyle] = 1
            attrs[.underlineColor] = color
        }
        return NSAttributedString(string: text, attributes: attrs)
    }
    
    /// 包含下划线富文本
    static func text(_ text: String, font: UIFont, color: UIColor,
                     underlines: [String], underlineColor: UIColor) -> NSAttributedString {
        let mAttri = NSMutableAttributedString()
        mAttri.append(NSAttributedString.ext.text(text, font: font, color: color))
        for underline in underlines {
            mAttri.addAttributes([.foregroundColor: underlineColor,
                                  .underlineColor: underlineColor,
                                  .underlineStyle: 1],
                                 range: underline.ext.nsRange(in: text))
        }
        return mAttri
    }
    
    /// 富文本图片
    /// - Parameters:
    ///   - image: 图片
    ///   - font: 字体
    ///   - offsetY: Y 轴偏移
    static func image(_ image: UIImage?, font: UIFont, offsetY: CGFloat = 2) -> NSAttributedString? {
        guard let image = image else { return nil }
        let attachment = NSTextAttachment()
        var attachH = image.size.height
        var attachW = image.size.width
        let fontH = font.lineHeight
        if attachH > fontH {
            attachH = fontH
            attachW = image.size.width/image.size.height * fontH
        }
        // bounds -> offseY 取反
        attachment.bounds = CGRect(x: 0, y: -offsetY, width: attachW, height: attachH)
        attachment.image = image
        return NSAttributedString(attachment: attachment)
    }

    /// 图片+文字 富文本
    /// - Parameters:
    ///   - image: 图片
    ///   - text: 文字内容
    ///   - font: 字体
    ///   - color: 颜色
    ///   - offsetY: Y 轴偏移
    static func imageText(image: UIImage?,
                          text: String,
                          font: UIFont,
                          color: UIColor,
                          offsetY: CGFloat = 2) -> NSAttributedString {
        NSAttributedString.ext.attris([
            NSAttributedString.ext.image(image, font: font, offsetY: offsetY),
            NSAttributedString.ext.text(text, font: font, color: color)
        ])
    }
    
    /// 文字+图片 富文本
    /// - Parameters:
    ///   - text: 文字
    ///   - image: 图片
    ///   - font: 字体
    ///   - color: 颜色
    ///   - offsetY: Y 轴偏移
    static func textImage(text: String,
                          image: UIImage?,
                          font: UIFont,
                          color: UIColor,
                          offsetY: CGFloat = 2) -> NSAttributedString {
        NSAttributedString.ext.attris([
            NSAttributedString.ext.text(text, font: font, color: color),
            NSAttributedString.ext.image(image, font: font, offsetY: offsetY)
        ])
    }
}

public extension ExtWrapper where Base: NSAttributedString {
    
    /**
     HTML Encoded String
     Reference:
        - https://stackoverflow.com/questions/25607247/how-do-i-decode-html-entities-in-swift
        - https://stackoverflow.com/questions/53954178/initialization-of-nsattributedstring-is-crashing-application
     */
    
    /// HTML 富文本
    static func html(_ htmlText: String?) -> NSAttributedString? {
        guard let data = htmlText?.data(using: .unicode) else { return nil }
        do {
            return try NSAttributedString(data: data,
                                          options: [.documentType: NSAttributedString.DocumentType.html],
                                          documentAttributes: nil)
        } catch {
            Ext.log("html decoded failure", error: error)
            return nil
        }
    }
    
    /// 添加阴影
    /// - Parameters:
    ///   - color: 阴影颜色
    ///   - blurRadius: 模糊半径
    ///   - offset: 偏移
    func shadow(color: UIColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3), blurRadius: CGFloat = 5, offset: CGSize = .zero) -> NSAttributedString {
        let shadow = NSShadow()
        shadow.shadowColor = color
        shadow.shadowBlurRadius = blurRadius
        shadow.shadowOffset = offset
        return addAttribute(.shadow, value: shadow)
    }
    
    /// 添加属性
    /// - Parameters:
    ///   - name: 属性名
    ///   - value: 属性值
    ///   - target: 目标文字
    func addAttribute(_ name: NSAttributedString.Key, value: Any, target: String? = nil) -> NSAttributedString {
        addAttributes([name: value], target: target)
    }
    
    /// 添加属性
    /// - Parameters:
    ///   - attrs: 属性字典
    ///   - target: 目标文字
    func addAttributes(_ attrs: [NSAttributedString.Key : Any] = [:], target: String? = nil) -> NSAttributedString {
        var range = NSRange(location: 0, length: base.length)
        if let target = target {
            range = (base.string as NSString).range(of: target)
        }
        let mAttri = NSMutableAttributedString(attributedString: base)
        mAttri.addAttributes(attrs, range: range)
        return mAttri
    }
}
