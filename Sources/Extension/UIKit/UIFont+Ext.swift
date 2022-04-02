//
//  UIFont+Ext.swift
//  Ext
//
//  Created by guojian on 2022/2/9.
//

import UIKit

public extension ExtWrapper where Base == UIFont {
    
    static func log() {
        for familyName in UIFont.familyNames {
            let fontNames = UIFont.fontNames(forFamilyName: familyName)
            print("family: \(familyName)")
            for fontName in fontNames {
                print("     name: \(fontName)")
            }
        }
    }
    
    enum FontKind {
        /// 常规
        case regular
        /// 粗体
        case bold
        /// 斜体
        case italic
    }
    
    /// 字体
    /// - Parameters:
    ///   - kind: 字体种类
    ///   - fontSize: 字体大小
    static func of(_ kind: FontKind, fontSize: CGFloat) -> UIFont {
        switch kind {
        case .regular:  return .systemFont(ofSize: fontSize)
        case .bold:     return .boldSystemFont(ofSize: fontSize)
        case .italic:   return .italicSystemFont(ofSize: fontSize)
        }
    }
}
