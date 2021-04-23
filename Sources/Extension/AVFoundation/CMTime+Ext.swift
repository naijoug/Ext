//
//  CMTime+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/26.
//

import AVFoundation

extension CMTime: ExtCompatible {}

public extension ExtWrapper where Base == Int {
    /// 毫秒 => CMTime
    func cmTime(timescale: Int32 = 1000) -> CMTime {
        return CMTimeMakeWithSeconds(Float64(base)/1000, preferredTimescale: timescale)
    }
    /// 毫秒 => NSValue(CMTTime())
    func cmTimeValue(timescale: Int32 = 1000) -> NSValue {
        return cmTime().ext.nsValue
    }
    /// 毫秒格式化显示 mm:ss
    var time: String {
        guard base > 0 else { return "00:00" }
        let minute = base/1000/60
        let sencond = lround(Double(base)/1000)%60
        return String(format: "%02d:%02d", minute, sencond)
    }
}

public extension ExtWrapper where Base == CMTime {
    /// 毫秒 (millisecond)
    var millisecond: Int { return Int(base.seconds * 1000) }
    
    /// 格式化显示 mm:ss
    var string: String {
        let seconds = base.seconds
        if seconds.isInfinite || seconds.isNaN {
            return "00:00"
        }
        return String(format: "%02d:%02d", Int(seconds)/60, Int(seconds)%60)
    }
    
    /// 包装 NSValue
    var nsValue: NSValue {
        return NSValue(time: base)
    }
}
