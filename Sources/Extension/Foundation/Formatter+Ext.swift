//
//  Formatter+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/28.
//

import Foundation

public extension ExtWrapper where Base == Formatter {
    
    
    /// 分割字符串
    /// - Parameters:
    ///   - string: 原始字符串
    ///   - separator: 分隔符
    /// - Returns: 分割后的字符串数组
    static func split(_ string: String?, by separator: Character) -> [String]? {
        return string?.split(separator: separator).map { String($0).trimmingCharacters(in: .whitespaces) }
    }
    
    /// 合并字符串
    /// - Parameters:
    ///   - array: 字符串数组
    ///   - connector: 连接符
    /// - Returns: 合并后的字符串
    static func merge(_ array: [String]?, by connector: Character) -> String? {
        guard let array = array, array.count > 0 else { return nil }
        var string = ""
        for i in 0..<array.count {
            if i != 0 { string += String(connector) }
            string += array[i]
        }
        return string.isEmpty ? nil : string
    }
}
