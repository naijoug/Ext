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
}

public extension ExtWrapper where Base == UIFont {
    /// 系统字体
    /// - Parameters:
    ///   - fontSize: 字体大小
    ///   - weight: 字体权重
    static func of(size fontSize: CGFloat, weight: UIFont.Weight) -> UIFont {
        UIFont.systemFont(ofSize: fontSize, weight: weight)
    }
    
    /**
     Reference:
        - https://stackoverflow.com/questions/61291811/how-to-implement-uikit-sf-pro-rounded
        - https://shorturl.at/crLY6
     */
    
    /// rounded 字体
    static func rounded(ofSize fontSize: CGFloat, weight: UIFont.Weight) -> UIFont {
        var font = UIFont.systemFont(ofSize: fontSize, weight: weight)
        if #available(iOS 13.0, *) {
            if let descriptor = font.fontDescriptor.withDesign(.rounded) {
                font = UIFont(descriptor: descriptor, size: fontSize)
            }
        } else {
            let name = ".AppleSystemUIFontRounded\(weight == .bold ? "-Bold" : "")"
            if let nameFont = UIFont(name: name, size: fontSize) {
                font = nameFont
            }
        }
        return font
    }
}
