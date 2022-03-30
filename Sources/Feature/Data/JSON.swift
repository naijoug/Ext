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
    
    /// 解析 JSON 数据
    static func parseDict(_ data: Any) -> [String: Any]? {
        if data is String, let string = data as? String {
            do {
                let json = try JSONSerialization.jsonObject(with: Data(string.utf8), options: [.allowFragments, .mutableLeaves])
                return json as? [String: Any]
            } catch {
                Ext.debug("parse JSON failed.", error: error)
            }
        } else if data is [String: Any], let json = data as? [String: Any] {
            return json
        }
        return nil
    }
    
}
