//
//  JSON.swift
//  Ext
//
//  Created by guojian on 2022/2/23.
//

import Foundation

public struct JSON {}

public extension JSON {
    
    /// 加载 JSON 文件
    static func load(_ filePath: String) -> Any? {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
            return try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
        } catch {
            Ext.debug("load JSON file failed.", error: error)
        }
        return nil
    }
    
    /// 解析 JSON 数据
    static func parse(_ data: Any) -> [String: Any]? {
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
