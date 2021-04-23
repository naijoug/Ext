//
//  Number+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/28.
//

import Foundation

extension Int: ExtCompatible {}
extension Float: ExtCompatible {}

public extension ExtWrapper where Base == Float {
    
    /// 保留小数位
    func decimal(_ decimal: Int = 2) -> String {
        let formater = NumberFormatter()
        formater.minimumFractionDigits = 0
        formater.maximumFractionDigits = 1
        return formater.string(from: NSNumber(value: base)) ?? String(format: "%.\(decimal)f", base)
    }
    
    /// 百分比
    /// - Parameter decimal: 最大保留小数点位数
    func percent(decimal: Int = 2) -> String {
        guard base < 1.0 else { return "100%" }
        guard base > 0.0 else { return "0%" }
        let formater = NumberFormatter()
        formater.numberStyle = .percent
        formater.maximumFractionDigits = decimal
        return formater.string(from: NSNumber(value: base)) ?? String(format: "%.\(decimal)f%%", base*100)
    }
}
