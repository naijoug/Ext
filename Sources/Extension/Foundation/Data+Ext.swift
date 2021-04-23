//
//  Data+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/28.
//

import Foundation

extension Data: ExtCompatible{}

extension ExtWrapper where Base == Data {
    
    /// 字符串
    public var string: String? { return String(data: base, encoding: .utf8) }
    
    /// 转化为16进制字符串
    public var hexString: String {
        /**
         - https://stackoverflow.com/questions/9372815/how-can-i-convert-my-device-token-nsdata-into-an-nsstring
         */
        return base.map { String(format: "%02.2hhx", $0) }.joined()
    }
    
    /// JSON 字符串
    public var JSONString: String? { return toJSONString() }
    
    /// 漂亮打印格式 JSON 字符串
    public var prettyPrintedJSONString: String? { return toJSONString(false) }
    
    /// Data 转化为 JSON
    ///
    /// - Parameter isPrettyPrinted: 漂亮打印格式
    private func toJSONString(_ isPrettyPrinted: Bool = false) -> String? {
        do {
            let object = try JSONSerialization.jsonObject(with: base, options: [])
            let data = try JSONSerialization.data(withJSONObject: object, options: isPrettyPrinted ? [.prettyPrinted] : [])
            return String(data: data, encoding: .utf8)
        } catch {
            Ext.debug("json deserialization error: \(error)")
            return nil
        }
    }

}
