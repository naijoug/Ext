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

public extension Ext.JSON {
    /// JSONObject -> String
    static func toString(jsonObject: Any?, prettyPrinted: Bool = false) -> String? {
        guard let jsonObject = jsonObject else { return nil }
        do {
            let options: JSONSerialization.WritingOptions = prettyPrinted ? [.prettyPrinted, .fragmentsAllowed] : [.fragmentsAllowed]
            let data = try JSONSerialization.data(withJSONObject: jsonObject, options: options)
            return String(data: data, encoding: .utf8)
        } catch {
            Ext.debug("jsonObject to string failed.", error: error)
            return nil
        }
    }
    /// Encodable -> String
    static func toString(_ value: Encodable?, prettyPrinted: Bool = false) -> String? {
        guard let value = value else { return nil }
        do {
            let data = try JSONEncoder().encode(value)
            guard prettyPrinted else {
                return String(data: data, encoding: .utf8)
            }
            return Ext.JSON.toString(jsonObject: data.ext.toJSONObject(), prettyPrinted: prettyPrinted)
        } catch {
            Ext.debug("encodable to string failed.", error: error)
            return nil
        }
    }
    
    /// String -> JSONObject
    static func toJSONObject(_ string: String?) -> Any? {
        guard let string = string, !string.isEmpty else { return nil }
        do {
            return try JSONSerialization.jsonObject(with: Data(string.utf8), options: [.allowFragments, .mutableLeaves])
        } catch {
            Ext.debug("string to jsonObject failed.", error: error)
            return nil
        }
    }
    /// Encodable -> JSONObject
    static func toJSONObject(_ value: Encodable?) -> Any? {
        guard let value = value else { return nil }
        do {
            let data = try JSONEncoder().encode(value)
            return try JSONSerialization.jsonObject(with: data, options: [.allowFragments, .mutableLeaves])
        } catch {
            Ext.debug("encodable to jsonObject failed.", error: error)
            return nil
        }
    }
    /// JSON file --> JSONObject
    static func toJSONObject(filePath: String) -> Any? {
        guard FileManager.default.fileExists(atPath: filePath) else {
            Ext.debug("JSON file not exist.", tag: .error)
            return nil
        }
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
            return try JSONSerialization.jsonObject(with: data, options: [.allowFragments, .mutableLeaves])
        } catch {
            Ext.debug("JSON file to jsonObject failed.", error: error)
            return nil
        }
    }
    
    /// String --> Decodable Model
    static func toModel<T: Decodable>(_ modeType: T.Type, string: String?) -> T? {
        guard let string = string else { return nil }
        do {
            return try JSONDecoder().decode(modeType, from: Data(string.utf8))
        } catch {
            Ext.debug("string to decodable failed.", error: error)
            return nil
        }
    }
    /// JSONObject --> Decodable Model
    static func toModel<T: Decodable>(_ modeType: T.Type, jsonObject: Any?) -> T? {
        guard let jsonObject = jsonObject else { return nil }
        do {
            let data = try JSONSerialization.data(withJSONObject: jsonObject, options: [.fragmentsAllowed])
            return try JSONDecoder().decode(modeType, from: data)
        } catch {
            Ext.debug("jsonObject to decodable failed.", error: error)
            return nil
        }
    }
    /// JSON file --> Decodeable Model
    static func toModel<T: Decodable>(_ modeType: T.Type, filePath: String) -> T? {
        guard FileManager.default.fileExists(atPath: filePath) else {
            Ext.debug("JSON file not exist.", tag: .error)
            return nil
        }
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
            return try JSONDecoder().decode(modeType, from: data)
        } catch {
            Ext.debug("JSON file to jsonObject failed.", error: error)
            return nil
        }
    }
}
