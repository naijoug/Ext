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
    
    /// data --> jsonString
    ///
    /// - Parameter isPrettyPrinted: 漂亮打印格式(换行展开)
    /// - Parameter errorLogged: JSON 解析失败是否打印错误日志 (默认: 打印)
    func toJSONString(_ isPrettyPrinted: Bool = false, errorLogged: Bool = true) -> String? {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: base)
            let data = try JSONSerialization.data(withJSONObject: jsonObject, options: isPrettyPrinted ? [.prettyPrinted] : [])
            return String(data: data, encoding: .utf8)
        } catch {
            Ext.debug("data to JSONString failed.", error: error, logEnabled: errorLogged, locationEnabled: false)
            return nil
        }
    }
    
    /// data --> jsonObject
    func toJSONObject(_ options: JSONSerialization.ReadingOptions = [.fragmentsAllowed, .allowFragments]) -> Any? {
        do {
            return try JSONSerialization.jsonObject(with: base)
        } catch {
            Ext.debug("data to JSONObject failed.", error: error, locationEnabled: false)
            return nil
        }
    }
    
    /// data --> decodable model
    func toModel<T: Decodable>(_ modelType: T.Type) -> T? {
        do {
            return try JSONDecoder().decode(modelType, from: base)
        } catch {
            Ext.debug("data to Decodable model failed.", error: error, locationEnabled: false)
            return nil
        }
    }
}

public extension Swift.Result where Success == Data, Failure == Swift.Error {
    /// data result --> jsonObject result
    func asJSONObject(_ options: JSONSerialization.ReadingOptions = [.fragmentsAllowed, .allowFragments]) -> Swift.Result<Any, Swift.Error> {
        flatMap { data in
            do {
                return .success(try JSONSerialization.jsonObject(with: data, options: options))
            } catch {
                Ext.debug("data as JSONObject failed.", error: error, locationEnabled: false)
                return .failure(Ext.Error.jsonDeserializationError(error: error))
            }
        }
    }
    /// data result --> decodable model result
    func asModel<T: Decodable>(_ modelType: T.Type) -> Swift.Result<T, Swift.Error> {
        flatMap { data in
            do {
                return .success(try JSONDecoder().decode(modelType, from: data))
            } catch {
                Ext.debug("data as Decodable model failed.", error: error, locationEnabled: false)
                return .failure(Ext.Error.jsonDecodeError(error: error))
            }
        }
    }
}
