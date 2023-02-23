//
//  JSON.swift
//  Ext
//
//  Created by guojian on 2022/2/23.
//

import Foundation

public extension Ext {
    enum JSON {}
}

// MARK: - toData
public extension Ext.JSON {
    /// String --> Data
    static func toData(_ string: String?) -> Data? {
        guard let string = string, !string.isEmpty else { return nil }
        return string.data(using: .utf8)
    }
    /// JSONObject --> Data
    static func toData(jsonObject: Any?, prettyPrinted: Bool = false) -> Data? {
        guard let jsonObject = jsonObject else { return nil }
        do {
            let options: JSONSerialization.WritingOptions = prettyPrinted ? [.prettyPrinted, .fragmentsAllowed] : [.fragmentsAllowed]
            return try JSONSerialization.data(withJSONObject: jsonObject, options: options)
        } catch {
            Ext.log("jsonObject to data failed.", error: error)
            return nil
        }
    }
    /// Encodable --> Data
    static func toData(_ value: Encodable?) -> Data? {
        guard let value = value else { return nil }
        do {
            return try JSONEncoder().encode(value)
        } catch {
            Ext.log("encodable to data failed.", error: error)
            return nil
        }
    }
    /// JSON file --> Data
    static func toData(filePath: String) -> Data? {
        guard FileManager.default.fileExists(atPath: filePath) else {
            Ext.log("JSON file not exist.", tag: .error)
            return nil
        }
        do {
            return try Data(contentsOf: URL(fileURLWithPath: filePath))
        } catch {
            Ext.log("JSON file to Data failed.", error: error)
            return nil
        }
    }
}

// MARK: - toString
public extension Ext.JSON {
    /// Data --> String
    static func toString(_ data: Data?) -> String? {
        guard let data = data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    /// JSONObject -> String
    static func toString(jsonObject: Any?, prettyPrinted: Bool = false) -> String? {
        toString(toData(jsonObject: jsonObject, prettyPrinted: prettyPrinted))
    }
    /// Encodable -> String
    static func toString(_ value: Encodable?) -> String? {
        toString(toData(value))
    }
}

// MARK: - toJSONObject
public extension Ext.JSON {
    /// Data --> JSONObject
    static func toJSONObject(_ data: Data?) -> Any? {
        guard let data = data else { return nil }
        do {
            return try JSONSerialization.jsonObject(with: data, options: [.allowFragments, .mutableLeaves])
        } catch {
            Ext.log("data to jsonObject failed.", error: error)
            return nil
        }
    }
    
    /// String -> JSONObject
    static func toJSONObject(_ string: String?) -> Any? {
        toJSONObject(toData(string))
    }
    /// Encodable -> JSONObject
    static func toJSONObject(_ value: Encodable?) -> Any? {
        toJSONObject(toData(value))
    }
    /// JSON file --> JSONObject
    static func toJSONObject(filePath: String) -> Any? {
        toJSONObject(toData(filePath: filePath))
    }
}

// MARK: - toModel(Encodable)
public extension Ext.JSON {
    /// Data --> Decodable
    static func toModel<T: Decodable>(_ modelType: T.Type, data: Data?) -> T? {
        guard let data = data else { return nil }
        do {
            return try JSONDecoder().decode(modelType, from: data)
        } catch {
            Ext.log("data to decodable failed.", error: error)
            return nil
        }
    }
    
    /// String --> Decodable
    static func toModel<T: Decodable>(_ modelType: T.Type, string: String?) -> T? {
        toModel(modelType, data: toData(string))
    }
    /// JSONObject --> Decodable
    static func toModel<T: Decodable>(_ modelType: T.Type, jsonObject: Any?) -> T? {
        toModel(modelType, data: toData(jsonObject: jsonObject))
    }
    /// JSON file --> Decodeable
    static func toModel<T: Decodable>(_ modelType: T.Type, filePath: String) -> T? {
        toModel(modelType, data: toData(filePath: filePath))
    }
}
