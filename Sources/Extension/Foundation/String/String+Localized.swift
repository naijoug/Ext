//
//  String+Localized.swift
//  Ext
//
//  Created by naijoug on 2021/5/7.
//

import Foundation

public extension Ext {
    /// 默认本地化语言
    static var LocalizedDefaultLangCode: String = "en"
    /// 本地化语言码
    static var LocalizedLangCode: String?
}

public extension ExtWrapper where Base == String {
    /// 本地化字符串
    var localized: String { return localized(code: Ext.LocalizedLangCode) }
    
    /// 指定语言码的本地化字符串
    /// - Parameters:
    ///   - code: 本地化语言码
    /// - Returns: 本地化处理之后的字符串
    func localized(code: String?) -> String {
        // Reference: https://stackoverflow.com/questions/27879232/force-nslocalizedstring-to-use-a-specific-language-using-swift
        var result = NSLocalizedString(base, comment: "")
        if let code = code,
            let path = Bundle.main.path(forResource: code, ofType: "lproj"),
            let bundle = Bundle(path: path) {
            result = NSLocalizedString(base, bundle: bundle, comment: "")
        } else {
            result = NSLocalizedString(base, comment: "")
        }
        // Ext.debug("code: \(String(describing: code)) | base: \(base) => result: \(result)")

        guard base == result, code != Ext.LocalizedDefaultLangCode else {
            return result
        }
        Ext.debug("base: \(base) => result: \(result)", tag: .custom("🌐"))
        return localized(code: Ext.LocalizedDefaultLangCode)
    }
}
