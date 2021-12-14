//
//  String+Localized.swift
//  Ext
//
//  Created by naijoug on 2021/5/7.
//

import Foundation

/**
 Reference:
    - https://stackoverflow.com/questions/27879232/force-nslocalizedstring-to-use-a-specific-language-using-swift
 */

public extension Ext {
    /// 本地化文件 Bundle
    static var localizedBundle: Bundle = .main
    /// 默认本地化语言
    static var LocalizedDefaultLangCode: String = "en"
    /// 本地化语言码
    static var LocalizedLangCode: String?
}

public extension ExtWrapper where Base == String {
    /// 本地化字符串
    var localized: String {
        localized(code: Ext.LocalizedLangCode ?? Ext.LocalizedDefaultLangCode, bundle: Ext.localizedBundle)
    }
    
    /// 指定语言码的本地化字符串
    /// - Parameters:
    ///   - code: 本地化语言码
    /// - Returns: 本地化处理之后的字符串
    func localized(code: String, bundle: Bundle? = nil) -> String {
        guard !base.isEmpty else { return base }
        let lprojBundle = (bundle ?? Ext.localizedBundle).ext.bundle(for: "\(code).lproj") ?? .main
        let result = lprojBundle.localizedString(forKey: base, value: nil, table: nil)
        //Ext.debug("code: \(String(describing: code)) | base: \(base) => result: \(result)")
        //Ext.debug("localized lproj path: \(lprojBundle.bundlePath)")
        guard base == result, code != Ext.LocalizedDefaultLangCode else { return result }
        // 如果指定的多语言处理不成功，再使用默认语言进行一次多语言处理
        //Ext.debug("default \(Ext.LocalizedDefaultLangCode) again | base: \(base) => result: \(result)", tag: .custom("🌐"))
        return localized(code: Ext.LocalizedDefaultLangCode)
    }
}
