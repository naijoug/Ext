//
//  String+Romanize.swift
//  Ext
//
//  Created by guojian on 2020/3/10.
//

import Foundation

/** Reference:
    - https://nshipster.com/cfstringtransform/
 */

// MARK: - OC System

public extension ExtWrapper where Base == String {
    
    /// 字符串转拉丁(拼音)
    ///
    /// - Parameters:
    ///   - hasTone: 是否含有音标
    
    func latin(hasTone: Bool = true, hasSpace: Bool = true) -> String {
        let mString = NSMutableString(string: base)
        // 转化为拼音
        CFStringTransform(mString, nil, kCFStringTransformToLatin, false)
        if !hasTone { // 去掉音标
            CFStringTransform(mString, nil, kCFStringTransformStripDiacritics, false)
        }
        
        let string = String(mString)
        if !hasSpace { // 去掉空格
            return string.replacingOccurrences(of: " ", with: "")
        }
        return string
    }
    
    /// 根据语言码对文字进行分词处理
    /// - Parameter lang: 语言码 (eg: 汉语 -> zh | 英语 -> en | 韩语 -> ko | 日语 -> ja)
    func tokenize(lang: String) -> [String] {
        var tokens = [String]()
        let tok = CFStringTokenizerCreate(nil, base as CFString, CFRangeMake(0, base.count), kCFStringTokenizerUnitWordBoundary, NSLocale(localeIdentifier: lang))
        
        var result = CFStringTokenizerAdvanceToNextToken(tok)
        while result.rawValue != 0 {
            let cfRange = CFStringTokenizerGetCurrentTokenRange(tok)
            let nsRange = NSRange(location: cfRange.location, length: cfRange.length)
            if let range = Range(nsRange, in: base) {
                tokens.append(String(base[range]))
            }
            result = CFStringTokenizerAdvanceToNextToken(tok)
        }
        return tokens
    }
    
}

// MARK: - Romanize

extension ExtWrapper where Base == String {
    
    /// 根据语言码返回罗马化音标
    /// - Parameters:
    ///   - lang: 语言码 (eg: 汉语 -> zh | 英语 -> en | 韩语 -> ko | 日语 -> ja | 俄语 -> ru )
    ///   - seperator: 分隔符 (默认: " ")
    public func romanize(lang: String, seperator: String = " ", hasTone: Bool = true, hasSpace: Bool = true) -> String {
        // 特殊处理语言码
        let langs = ["ko", "ja", "ru"]
        guard langs.contains(lang) else { // 非特殊语言，使用 OC 系统方法
            return latin(hasTone: hasTone, hasSpace: hasSpace)
        }
        
        // 韩语处理
        if lang == "ko" { return romanizeKorean() }
        
        guard let regex1 = try? NSRegularExpression(pattern: "([aiueoāīūēō])([aiueoāīūēōymngkzjbsrhdtwc])", options: .caseInsensitive),
              let regex2 = try? NSRegularExpression(pattern: "( n)([ymngkzbsrhdtjwc])", options: .caseInsensitive) else {
            return ""
        }
        
        let text = base.filter({ !String($0).ext.isSingleEmoji }) // filter emoji => fix convert utf8 string error
        let tok = CFStringTokenizerCreate(nil, text as CFString, CFRangeMake(0, text.count), kCFStringTokenizerUnitWord, NSLocale(localeIdentifier: lang))
        
        var result = CFStringTokenizerAdvanceToNextToken(tok)
        var tokens = [String]()
        while result.rawValue != 0 {
            let cTypeRef =  CFStringTokenizerCopyCurrentTokenAttribute(tok, kCFStringTokenizerAttributeLatinTranscription)
            if let arg = cTypeRef as? CVarArg {
                var str = String(format: "%@", arg)
                //print("\(base) | \(text) --> \(arg) | \(str)")
                if lang == "ja" { // 日语
                    str = regex1.stringByReplacingMatches(in: str, options: [], range: NSRange(location: 0, length: str.count), withTemplate: "$1 $2")
                    str = regex1.stringByReplacingMatches(in: str, options: [], range: NSRange(location: 0, length: str.count), withTemplate: "$1 $2") // 做两次才可以
                    str = regex2.stringByReplacingMatches(in: str, options: [], range: NSRange(location: 0, length: str.count), withTemplate: "$1 $2")
                }
                tokens.append(str)
            }
            result = CFStringTokenizerAdvanceToNextToken(tok)
        }
        return tokens.joined(separator: seperator)
    }
    
}

// MARK: - Korean

extension ExtWrapper where Base == String {
    
    /// 韩语罗马化
    func romanizeKorean() -> String {
        var strs = [String]()
        for i in 0..<base.count {
            let index = base.index(base.startIndex, offsetBy: i)
            guard let charCode = base[index].unicodeScalars.first?.value else { continue }
            if charCode < ExtWrapper.UNICODE_KO_MIN || ExtWrapper.UNICODE_KO_MAX <= charCode { continue }
            var unicodeOffset = Int(charCode - ExtWrapper.UNICODE_KO_MIN)
            let trailerOffset = unicodeOffset % ExtWrapper.KO_CONSONANTS_F.count
            unicodeOffset -= trailerOffset
            unicodeOffset /= ExtWrapper.KO_CONSONANTS_F.count
            let vowelOffset = unicodeOffset % ExtWrapper.KO_VOWELS.count
            unicodeOffset -= vowelOffset
            unicodeOffset /= ExtWrapper.KO_VOWELS.count
            let leadOffset = unicodeOffset
            
            let unit = ExtWrapper.KO_CONSONANTS_I[leadOffset] + ExtWrapper.KO_VOWELS[vowelOffset] + ExtWrapper.KO_CONSONANTS_F[trailerOffset]
            strs.append(unit)
        }
        return strs.joined(separator: " ")
    }
    
    static let UNICODE_KO_MIN: UInt32 = 44032
    static let UNICODE_KO_MAX: UInt32 = 55215
    static let KO_VOWELS = [
        "a",   // ㅏ
        "ae",  // ㅐ
        "ya",  // ㅑ
        "yae", // ㅒ
        "eo",  // ㅓ
        "e",   // ㅔ
        "yeo", // ㅕ
        "ye",  // ㅖ
        "o",   // ㅗ
        "wa",  // ㅘ
        "wae", // ㅙ
        "oe",  // ㅚ
        "yo",  // ㅛ
        "u",   // ㅜ
        "wo",  // ㅝ
        "we",  // ㅞ
        "wi",  // ㅟ
        "yu",  // ㅠ
        "eu",  // ㅡ
        "ui",  // ㅢ
        "i"    // ㅣ
    ]
    static let KO_CONSONANTS_I = [
        "g",  // ㄱ
        "kk", // ㄲ
        "n",  // ㄴ
        "d",  // ㄷ
        "tt", // ㄸ
        "r",  // ㄹ
        "m",  // ㅁ
        "b",  // ㅂ
        "pp", // ㅃ
        "s",  // ㅅ
        "ss", // ㅆ
        "",   // ㅇ
        "j",  // ㅈ
        "jj", // ㅉ
        "ch", // ㅊ
        "k",  // ㅋ
        "t",  // ㅌ
        "p",  // ㅍ
        "h"   // ㅎ
    ]
    static let KO_CONSONANTS_F = [
        "",
        "k",  // ㄱ
        "k",  // ㄲ
        "k", // ㄳ
        "n",  // ㄴ
        "n", // ㄵ
        "n", // ㄶ
        "t",  // ㄷ
        "l",  // ㄹ
        "l", // ㄺ
        "l", // ㄻ
        "l", // ㄼ
        "l", // ㄽ
        "l", // ㄾ
        "l", // ㄿ
        "l", // ㅀ
        "m",  // ㅁ
        "p",  // ㅂ
        "p", // ㅄ
        "t",  // ㅅ
        "t", // ㅆ
        "ng", // ㅇ
        "t",  // ㅈ
        "t",  // ㅊ
        "k",  // ㅋ
        "t",  // ㅌ
        "p",  // ㅍ
        "h"   // ㅎ
    ]
}
