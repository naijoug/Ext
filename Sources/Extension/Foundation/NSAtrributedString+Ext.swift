//
//  NSAttributedString+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/28.
//

import Foundation

public extension ExtWrapper where Base == NSAttributedString {
        
    
    /// 富文本拼接
    /// - Parameter attris: 富文本数组
    static func attris(_ attris: [NSAttributedString?]) -> NSAttributedString {
        let mAttri = NSMutableAttributedString()
        for attri in attris {
            if let attri = attri {
                mAttri.append(attri)
            }
        }
        return mAttri
    }
    
    /// 富文本文字
    /// - Parameters:
    ///   - text: 文字内容
    ///   - fontSize: 字体大小
    ///   - color: 字体颜色
    ///   - hasBold: 是否加粗
    ///   - hasUnderline: 是否有下划线
    static func text(_ text: String,
                     fontSize: CGFloat,
                     color: UIColor,
                     hasBold: Bool = false,
                     hasUnderline: Bool = false) -> NSAttributedString {
        return NSAttributedString.ext.text(text,
                                           font: hasBold ? UIFont.boldSystemFont(ofSize: fontSize) : UIFont.systemFont(ofSize: fontSize),
                                           color: color,
                                           hasUnderline: hasUnderline)
    }
    
    /// 富文本文字
    /// - Parameters:
    ///   - text: 文字内容
    ///   - font: 字体
    ///   - color: 字体颜色
    ///   - hasUnderline: 是否有下划线
    static func text(_ text: String,
                     font: UIFont,
                     color: UIColor,
                     hasUnderline: Bool = false) -> NSAttributedString {
        var attrs = [NSAttributedString.Key : Any]()
        attrs[.font] = font
        attrs[.foregroundColor] = color
        if hasUnderline {
            attrs[.underlineStyle] = 1
            attrs[.underlineColor] = color
        }
        return NSAttributedString(string: text, attributes: attrs)
    }
    
    
    /// 富文本图片
    /// - Parameters:
    ///   - image: 图片
    ///   - font: 字体
    ///   - offsetY: Y 轴偏移
    static func image(_ image: UIImage?,
                      font: UIFont,
                      offsetY: CGFloat = 0) -> NSAttributedString? {
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
    
    /// 富文本图片
    /// - Parameters:
    ///   - imageNamed: 图片
    ///   - font: 字体
    ///   - offsetY: Y 轴偏移
    static func image(imageNamed: String?,
                      font: UIFont,
                      offsetY: CGFloat = 0) -> NSAttributedString? {
        guard let imageNamed = imageNamed else { return nil }
        return NSAttributedString.ext.image(UIImage(named: imageNamed), font: font, offsetY: offsetY)
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
                          offsetY: CGFloat = 0) -> NSAttributedString {
        return NSAttributedString.ext.attris([
            NSAttributedString.ext.image(image, font: font, offsetY: offsetY),
            NSAttributedString.ext.text(text, font: font, color: color)
        ])
    }
    
    /// 图片+文字 富文本
    /// - Parameters:
    ///   - imageNamed: 图片名称
    ///   - text: 文字内容
    ///   - font: 字体
    ///   - color: 颜色
    ///   - offsetY: Y 轴偏移
    static func imageText(imageNamed: String,
                          text: String,
                          font: UIFont,
                          color: UIColor,
                          offsetY: CGFloat = 0) -> NSAttributedString {
        return imageText(image: UIImage(named: imageNamed),
                         text: text, font: font, color: color, offsetY: offsetY)
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
                          offsetY: CGFloat = 0) -> NSAttributedString {
        return NSAttributedString.ext.attris([
            NSAttributedString.ext.text(text, font: font, color: color),
            NSAttributedString.ext.image(image, font: font, offsetY: offsetY)
        ])
    }
    
    /// 文字+图片 富文本
    /// - Parameters:
    ///   - text: 文字
    ///   - imageNamed: 图片名称
    ///   - font: 字体
    ///   - color: 颜色
    ///   - offsetY: Y 轴偏移
    static func textImage(text: String,
                          imageNamed: String,
                          font: UIFont,
                          color: UIColor,
                          offsetY: CGFloat = 0) -> NSAttributedString {
        return textImage(text: text, image: UIImage(named: imageNamed), font: font, color: color, offsetY: offsetY)
    }
    
}

public extension ExtWrapper where Base == NSAttributedString {
    
    /// HTML 富文本
    static func html(_ htmlText: String?) -> NSAttributedString? {
        guard let data = htmlText?.data(using: .unicode) else { return nil }
        do {
            return try NSAttributedString(data: data,
                                          options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html],
                                          documentAttributes: nil)
        } catch {
            return nil
        }
    }
    
}
