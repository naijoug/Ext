//
//  Data+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/28.
//

import Foundation

extension Data: ExtCompatible {}

public extension ExtWrapper where Base == Data {
    
    /// 字符串
    var string: String? { String(data: base, encoding: .utf8) }
    
    /**
     Reference
        - https://stackoverflow.com/questions/9372815/how-can-i-convert-my-device-token-nsdata-into-an-nsstring
     */
    
    /// 转化为16进制字符串
    var hexString: String { base.map { String(format: "%02.2hhx", $0) }.joined() }
    
    /// data --> json string
    ///
    /// - Parameter isPrettyPrinted: 漂亮打印格式(换行展开)
    /// - Parameter errorLogged: JSON 解析失败是否打印错误日志 (默认: 打印)
    func toJSONString(_ isPrettyPrinted: Bool = false, errorLogged: Bool = true) -> String? {
        do {
            let object = try JSONSerialization.jsonObject(with: base, options: [])
            let data = try JSONSerialization.data(withJSONObject: object, options: isPrettyPrinted ? [.prettyPrinted] : [])
            return String(data: data, encoding: .utf8)
        } catch {
            Ext.debug("JSON deserialization error", error: error, logEnabled: errorLogged, locationEnabled: false)
            return nil
        }
    }
    
    /// data --> json result
    func asJSON(_ options: JSONSerialization.ReadingOptions = [.fragmentsAllowed, .allowFragments]) -> Swift.Result<Any, Swift.Error> {
        do {
            let json = try JSONSerialization.jsonObject(with: base, options: options)
            return .success(json)
        } catch {
            return .failure(Ext.Error.jsonDeserializationError(error: error))
        }
    }
    /// data --> decodable result
    func asCode<T: Decodable>(_ dataType: T.Type) -> Swift.Result<T, Swift.Error> {
        do {
            let decoder = JSONDecoder()
            let decodedData = try decoder.decode(dataType, from: base)
            return .success(decodedData)
        } catch {
            return .failure(Ext.Error.jsonDecodedError(error: error))
        }
    }
}
