//
//  Number+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/28.
//

import Foundation

extension Int: ExtCompatible {}
extension Float: ExtCompatible {}
extension Double: ExtCompatible {}

public extension ExtWrapper where Base == Int {
    /// 毫秒 -> 秒
    var msecToSec: TimeInterval { TimeInterval(base) / 1000.0 }
}
public extension ExtWrapper  where Base == TimeInterval {
    /// 秒 -> 毫秒
    var secToMsec: Int { Int(Darwin.round(base * 1000)) }
}

public extension ExtWrapper where Base == Float {
    
    /// 保留小数位
    func decimal(_ decimal: Int = 2) -> String {
        let formater = NumberFormatter()
        formater.minimumFractionDigits = 0
        formater.maximumFractionDigits = decimal
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

public extension ExtWrapper where Base == Double {
    /// 保留小数位
    func decimal(_ decimal: Int = 2) -> String {
        let formater = NumberFormatter()
        formater.minimumFractionDigits = 0
        formater.maximumFractionDigits = decimal
        return formater.string(from: NSNumber(value: base)) ?? String(format: "%.\(decimal)f", base)
    }
}

public extension ExtWrapper where Base == TimeInterval {
    /// 时长串 xx:xx:xx
    var timeString: String {
        let total = Int(ceil(base))
        let second = total % 60
        let minute = (total / 60) % 60
        let hour = total / 60 / 60
        //Ext.debug("total: \(total) | hour: \(hour) minute: \(minute) | second: \(second)")
        let formater = "%02d"
        return "\(hour > 0 ? "\(formater.ext.format(hour)):" : "")\(formater.ext.format(minute)):\(formater.ext.format(second))"
    }
}
