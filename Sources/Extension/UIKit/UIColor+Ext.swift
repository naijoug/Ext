//
//  UIColor+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/28.
//

import UIKit

extension ExtWrapper where Base == UIColor {

    // Reference : https://stackoverflow.com/questions/24074257/how-can-i-use-uicolorfromrgb-in-swift

    
    /// 使用十六进制 RGB 字符串创建颜色
    /// - Parameter hex: 十六进制字符串 (eg: #FF00FF)
    public static func rgbHex(_ hex: String, alpha: CGFloat = 1.0) -> UIColor {
        var hexString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if hexString.hasPrefix("#") {
            hexString.remove(at: hexString.startIndex)
        }
        assert(hexString.count == 6, "The color hex string length is not 6.")

        var rgbValue: UInt32 = 0
        Scanner(string: hex).scanHexInt32(&rgbValue)
        return rgbHex(UInt(rgbValue), alpha: alpha)
    }
    
    /// 使用十六进制 RGB 创建颜色
    /// - Parameter hex: 十六进制 RGB (eg: 0xff0000)
    public static func rgbHex(_ hex: UInt, alpha: CGFloat = 1.0) -> UIColor {
        assert(0...0xFFFFFF ~= hex, "The color hex value must between 0 to 0xFFFFFF.")
        return rgb(
            red: (hex & 0xFF0000) >> 16,
            green: (hex & 0x00FF00) >> 8,
            blue: (hex & 0x0000FF),
            alpha: alpha
        )
    }
        
    /// 使用 RGB 值(0 ~ 255) 创建颜色
    /// - Parameters:
    ///   - red: 红
    ///   - green: 绿
    ///   - blue: 蓝
    public static func rgb(red: UInt, green: UInt, blue: UInt, alpha: CGFloat = 1.0) -> UIColor {
        assert(0 <= red && red <= 255, "Invalid red component")
        assert(0 <= green && green <= 255, "Invalid green component")
        assert(0 <= blue && blue <= 255, "Invalid blue component")
        return UIColor(
            red: CGFloat(red) / 255.0,
            green: CGFloat(green) / 255.0,
            blue: CGFloat(blue) / 255.0,
            alpha: alpha
        )
    }
    
}
