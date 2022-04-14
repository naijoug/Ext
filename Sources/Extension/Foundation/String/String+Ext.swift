//
//  String+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/28.
//

import Foundation

extension String: ExtCompatible {}
extension Character: ExtCompatible {}

/**
 let str = "abcdef"
 str[1 ..< 3] // returns "bc"
 str[5] // returns "f"
 str[80] // returns ""
 str.substring(fromIndex: 3) // returns "def"
 str.substring(toIndex: str.length - 2) // returns "abcd"
 */
public extension String {
    /// 对应索引的子串
    ///
    /// - Parameter i: 索引位置
    subscript (i: Int) -> String {
        return self[i ..< i + 1]
    }
    
    /// Range 范围子串
    ///
    /// - Parameter r: Range 范围
    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(count, r.lowerBound)),
                                            upper: min(count, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
    
    /// 从索引开始的子串
    ///
    /// - Parameter fromIndex: 起始索引
    /// - Returns: 子串
    func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, count) ..< count]
    }
    
    /// 到结束索引的子串
    ///
    /// - Parameter toIndex: 结束索引
    /// - Returns: 子串
    func substring(toIndex: Int) -> String {
        return self[0 ..< max(0, toIndex)]
    }
}

public extension ExtWrapper where Base == String {
    
    /// 去除前后空格 & 换行
    var trim: String? { return base.trimmingCharacters(in: .whitespacesAndNewlines) }
    
    /// NSRange in text
    func nsRange(in text: String) -> NSRange { (text as NSString).range(of: base) }
    
    /// 国家码 -> 国旗字符 (eg: CN -> 🇨🇳)
    var countryFlag: String {
        let basic = 127397
        let usv = base.uppercased().utf16
            .map { basic + Int($0) }
            .compactMap(UnicodeScalar.init)
            .reduce(String.UnicodeScalarView()) { $0 + [$1] }
        return String(usv)
    }
}

public extension ExtWrapper where Base == String {
    
    /// 删除前缀
    func removePrefix(_ prefix: String) -> String {
        guard base.hasPrefix(prefix) else { return base }
        return String(base.dropFirst(prefix.count))
    }
    /// 删除后缀
    func removeSuffix(_ suffix: String) -> String {
        guard base.hasSuffix(suffix) else { return base }
        return String(base.dropLast(suffix.count))
    }
    
    /// 分割字符串
    func split(_ separator: Character) -> [String] {
        base.split(separator: separator).compactMap({ String($0) })
    }
}

public extension ExtWrapper where Base == String {
    
    /// test swift format
    func test() {
        // https://stackoverflow.com/questions/52332747/what-are-the-supported-swift-string-format-specifiers
        Ext.debug("\(String(format: "%2$@ %1$@", "world", "Hello"))")
    }
    
    /**
     Reference:
        - https://stackoverflow.com/questions/40626006/formatting-string-with-in-swift
     */
    
    func format(_ arguments: CVarArg...) -> String {
        format(arguments: arguments)
    }
    
    func format(arguments: [CVarArg]) -> String {
        /// 是否有效格式化字符串
        func checkValid() -> Bool {
            switch arguments.count {
            case 1:
                let arg0 = arguments[0]
                if arg0 is Int                              { return base.contains("%d") }
                else if arg0 is Float || arg0 is Double     { return base.contains("%f") }
                else if arg0 is String                      { return base.contains("%@") }
            default: () // TODO: fix more arg
            }
            return true
        }
        let isValid = checkValid()
        Ext.debug("\(isValid) | \(base) | \(arguments)")
        return isValid ? String(format: base, arguments: arguments) : base
    }
}

public extension ExtWrapper where Base == String {
    
    /**
     首字符大写

     string:           toDo
     uppercased:       TODO
     capitalized:      Todo
     firstCapitalized: ToDo
     
     string:           hello world.
     uppercased:       HELLO WORLD.
     capitalized:      Hello World.
     firstCapitalized: Hello world.
     
     Reference:
        - https://stackoverflow.com/questions/26306326/swift-apply-uppercasestring-to-only-the-first-letter-of-a-string
     */
    var firstCapitalized: String { base.prefix(1).capitalized + base.dropFirst() }
    
    /// 解码 html 字符串
    var htmlDecoded: String? { NSAttributedString.ext.html(base)?.string }
}

// MARK: - Emoji

/**
Reference
    - https://stackoverflow.com/questions/30757193/find-out-if-character-in-string-is-emoji
    - 注: Unicode Character Code Charts : http://www.unicode.org/charts/#symbols
*/

extension ExtWrapper where Base == Character {
    /// 是否为单一表情
    var isSimpleEmoji: Bool {
        guard let firstScalar = base.unicodeScalars.first else { return false }
        return firstScalar.properties.isEmoji && firstScalar.value > 0x238C
    }
    /// 是否为合并表情
    var isCombinedIntoEmoji: Bool { base.unicodeScalars.count > 1 && base.unicodeScalars.first?.properties.isEmoji ?? false }

    /// 是否为表情字符
    var isEmoji: Bool { isSimpleEmoji || isCombinedIntoEmoji }
}

public extension ExtWrapper where Base == String {
    
    /// 是否单个表情
    var isSingleEmoji: Bool { base.count == 1 && containsEmoji }
    /// 是否包含表情
    var containsEmoji: Bool { base.contains { $0.ext.isEmoji } }
    /// 是否仅包含表情
    var containsOnlyEmoji: Bool { !base.isEmpty && !base.contains { !$0.ext.isEmoji } }
    /// 字符串中的表情字符串
    var emojiString: String { emojis.map { String($0) }.reduce("", +) }
    
    /// 包含的表情字符
    var emojis: [Character] { base.filter { $0.ext.isEmoji } }
    /// 表情
    var emojiScalars: [UnicodeScalar] { base.filter { $0.ext.isEmoji }.flatMap { $0.unicodeScalars } }
    
    
    
    /// 正则表达式替换
    /// - Parameters:
    ///   - pattern: 匹配的正则表达式
    ///   - with: 替换字符
    ///   - options:
    func regexReplace(pattern: String,
                      with: String,
                      options: NSRegularExpression.Options = [.caseInsensitive]) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return base }
        return regex.stringByReplacingMatches(in: base, options: [],
                                              range: NSRange(location: 0, length: base.count),
                                              withTemplate: with)
    }
}

// MARK: - Crypto

import var CommonCrypto.CC_MD5_DIGEST_LENGTH
import func CommonCrypto.CC_MD5
import typealias CommonCrypto.CC_LONG

extension ExtWrapper where Base == String {

    /// reference : https://stackoverflow.com/questions/32163848/how-can-i-convert-a-string-to-an-md5-hash-in-ios-using-swift
    
    /// md5 转化
    public var md5: String {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        let messageData = base.data(using: .utf8)!
        var digestData = Data(count: length)

        _ = digestData.withUnsafeMutableBytes { digestBytes -> UInt8 in
            messageData.withUnsafeBytes { messageBytes -> UInt8 in
                if let messageBytesBaseAddress = messageBytes.baseAddress, let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
                    let messageLength = CC_LONG(messageData.count)
                    CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
                }
                return 0
            }
        }
        return digestData.map { String(format: "%02hhx", $0) }.joined()
    }

    /// base64 编码
    public func base64Encoded() -> String? {
        return base.data(using: .utf8)?.base64EncodedString()
    }
    
    /// base64 解码
    public func base64Decoded() -> String? {
        guard let data = Data(base64Encoded: base) else { return nil }
        return String(data: data, encoding: .utf8)
    }

}
