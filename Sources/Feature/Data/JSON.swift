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
            let data = Data(string.utf8)
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [.allowFragments, .mutableLeaves])
            return jsonObject
        } catch {
            Ext.debug("string to jsonObject failed.", error: error)
            return nil
        }
    }
    /// String -> JSONObject
    static func toJSONObject(_ value: Encodable?) -> Any? {
        guard let value = value else { return nil }
        do {
            let data = try JSONEncoder().encode(value)
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [.allowFragments, .mutableLeaves])
            return jsonObject
        } catch {
            Ext.debug("encodable to jsonObject failed.", error: error)
            return nil
        }
    }
}

public extension Ext.JSON {
    /// 从 JSON 文件中加载 JSON Dict
    static func loadDict(_ filePath: String) -> [String: Any]? {
        load(filePath) as? [String: Any]
    }
    /// 从 JSON 文件中加载 JSON Array
    static func loadArray(_ filePath: String) -> [Any]? {
        load(filePath) as? [Any]
    }
    
    /// 加载 JSON 文件
    private static func load(_ filePath: String) -> Any? {
        guard FileManager.default.fileExists(atPath: filePath) else {
            Ext.debug("load JSON file not exist.", tag: .error)
            return nil
        }
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
            return try JSONSerialization.jsonObject(with: data, options: [.allowFragments, .mutableLeaves])
        } catch {
            Ext.debug("load JSON file failed.", error: error)
        }
        return nil
    }
}
