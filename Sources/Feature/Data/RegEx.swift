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
        NSPredicate(format:"SELF MATCHES %@", rawValue).evaluate(with: string)
    }
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

public extension Ext.RegEx {
    struct MatchResult {
        /// 匹配范围
        public let range: NSRange
        /// 匹配文本
        public let match: String
    }
    
    /// 正则解析文本
    /// - Parameters:
    ///   - text: 文本
    ///   - pattern: 正则模式串
    /// - Returns: 解析匹配结果(倒序)
    static func parse(_ text: String, pattern: String) -> [MatchResult]? {
        guard let regEx = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        /**
         fix: 文本包含 emoji 时 match 文本匹配有误
         https://stackoverflow.com/questions/27880650/swift-extract-regex-matches
         */
        let results = regEx.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
                            .reversed()
        return results.compactMap { result in
            guard let range = Range(result.range, in: text) else { return nil }
            return MatchResult(range: result.range, match: String(text[range]))
        }
    }
    
    
    /// 正则替换
    /// - Parameters:
    ///   - text: 要处理的文本
    ///   - with: 替换字符
    ///   - pattern: 正则模式串
    ///   - options: 正则选项
    func replace(_ text: String, with: String, pattern: String,
                 options: NSRegularExpression.Options = [.caseInsensitive]) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return text }
        return regex.stringByReplacingMatches(
            in: text, options: [],
            range: NSRange(location: 0, length: text.count),
            withTemplate: with
        )
    }
}
