//
//  Bundle+Ext.swift
//  Ext
//
//  Created by guojian on 2021/9/22.
//

import Foundation

public extension ExtWrapper where Base == Bundle {
    
    /*
     Reference:
        - https://stackoverflow.com/questions/31316325/how-to-get-bundle-for-a-struct
     */
    
    /// Bundle
    /// - Parameters:
    ///   - cls: bundle Class
    ///   - bundleName: bundle 名
    /// - Returns: 如果 bundle 不存在，返回 mainBundle
    static func bundle(for cls: AnyClass? = nil, bundleName: String) -> Bundle {
        var bundle = Bundle.main
        if let cls = cls { bundle = Bundle(for: cls) }
        let bundlePath = bundle.path(forResource: bundleName, ofType: "bundle")
        Ext.debug("bundlePath: \(bundlePath ?? "")", locationEnabled: false)
        guard let path = bundlePath else { return Bundle.main }
        return Bundle(path: path) ?? .main
    }
    
    
    /// Bundle 文件路径
    /// - Parameters:
    ///   - cls: bundle Class
    ///   - bundleName: bundle 名
    ///   - filePath: bundle 文件路径
    /// - Returns: 文件路径
    static func path(for cls: AnyClass? = nil, bundleName: String, filePath: String) -> String? {
        return bundle(for: cls, bundleName: bundleName).path(forResource: filePath, ofType: nil)
    }
    
    /// 获取 Bundle 文件路径
    func filePath(_ filePath: String) -> String { (base.bundlePath as NSString).appendingPathComponent(filePath) }
}
