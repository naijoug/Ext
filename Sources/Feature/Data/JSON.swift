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
    
    /// Dict -> String
    static func toString(_ dict: [String: Any]?, prettyPrinted: Bool = false) -> String? {
        guard let dict = dict, !dict.isEmpty else { return nil }
        do {
            let options: JSONSerialization.WritingOptions = prettyPrinted ? [.prettyPrinted, .fragmentsAllowed] : [.fragmentsAllowed]
            let data = try JSONSerialization.data(withJSONObject: dict, options: options)
            return String(data: data, encoding: .utf8)
        } catch {
            Ext.debug("dict to string failed.", error: error)
        }
        return nil
    }
    /// String -> Dict
    static func toDict(_ string: String?) -> [String: Any]? {
        guard let string = string, !string.isEmpty else { return nil }
        do {
            let data = Data(string.utf8)
            let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments, .mutableLeaves])
            return json as? [String: Any]
        } catch {
            Ext.debug("string to dict failed.", error: error)
        }
        return nil
    }
    
    /// Any -> Dict
    static func toDict(_ anyData: Any?) -> [String: Any]? {
        guard let anyData = anyData else { return nil }
        if anyData is String, let string = anyData as? String {
            return toDict(string)
        } else if anyData is [String: Any], let json = anyData as? [String: Any] {
            return json
        }
        return nil
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
