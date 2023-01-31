//
//  NSLocale+Ext.swift
//  Ext
//
//  Created by guojian on 2023/1/31.
//

import Foundation

public extension ExtWrapper where Base == NSLocale {
    /**
     偏好设置语言 : 从用户系统中读取，去除国家码后缀(eg: "-US")之后的语言码
     eg: [zh-Hans-CN, en-US, zh-Hant-CN] --> [zh, en]
     */
    static var preferredLanguageCodes: [String] {
        Base.preferredLanguages
            .compactMap { $0.split(separator: "-").first }
            .map { String($0) }
            .reduce(into: []) { result, element in
                guard !result.contains(element) else { return }
                result.append(element)
            }
    }
}
