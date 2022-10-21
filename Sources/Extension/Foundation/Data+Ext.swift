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
            let jsonObject = try JSONSerialization.jsonObject(with: base, options: [])
            let data = try JSONSerialization.data(withJSONObject: jsonObject, options: isPrettyPrinted ? [.prettyPrinted] : [])
            return String(data: data, encoding: .utf8)
        } catch {
            Ext.debug("JSON deserialization error", error: error, logEnabled: errorLogged, locationEnabled: false)
            return nil
        }
    }
    
    /// data --> jsonObject result
    func asJSONObject(_ options: JSONSerialization.ReadingOptions = [.fragmentsAllowed, .allowFragments]) -> Swift.Result<Any, Swift.Error> {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: base, options: options)
            return .success(jsonObject)
        } catch {
            return .failure(Ext.Error.jsonDeserializationError(error: error))
        }
    }
    /// data --> model result
    func asModel<T: Decodable>(_ dataType: T.Type) -> Swift.Result<T, Swift.Error> {
        do {
            let decoder = JSONDecoder()
            let model = try decoder.decode(dataType, from: base)
            return .success(model)
        } catch {
            return .failure(Ext.Error.jsonDecodeError(error: error))
        }
    }
}
