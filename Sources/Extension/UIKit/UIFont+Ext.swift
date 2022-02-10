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
