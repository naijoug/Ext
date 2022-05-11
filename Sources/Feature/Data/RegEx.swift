//
//  RegEx.swift
//  Ext
//
//  Created by naijoug on 2022/5/5.
//

import Foundation

public extension Ext {
    /// 常用正则表达式 (Regular Expressions)
    enum RegEx: String {
        /// 邮箱正则
        case email = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    }
}

/**
 Reference
    - https://stackoverflow.com/questions/25471114/how-to-validate-an-e-mail-address-in-swift
 */

public extension Ext.RegEx {
    
    /// 字符串是否有效
    /// - Parameter string: 校验的字符串
    func isValid(_ string: String) -> Bool {
        NSPredicate(format:"SELF MATCHES %@", self.rawValue).evaluate(with: string)
    }
    
}

public extension Ext.RegEx {
    
    /// 字符串是否匹配正则
    /// - Parameters:
    ///   - string: 字符串
    ///   - pattern: 正则模式串
    static func isVaild(_ string: String, pattern: String) -> Bool {
        guard let regEx = try? NSRegularExpression(pattern: pattern, options: []) else { return false }
        let results = regEx.matches(in: string, range: NSRange(location: 0, length: string.utf16.count))
        return !results.isEmpty
    }
    
}
