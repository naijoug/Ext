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
        - https://stackoverflow.com/questions/41834472/xcode8-usage-of-image-literals-in-frameworks
     */
    
    /// Bundle
    /// - Parameters:
    ///   - cls: 类名 (不能为嵌套内部类)
    ///   - bundleName: bundle 名 (如果 cls != nil，默认是 cls 所在的模块名)
    /// - Returns: 如果 bundle 不存在，返回 mainBundle
    static func bundle(for cls: AnyClass? = nil, bundleName: String? = nil) -> Bundle {
        var bundle = Bundle.main
        var name = bundleName
        if let cls = cls {
            bundle = Bundle(for: cls)
            name = name ?? String(reflecting: cls).components(separatedBy: ".").first
        }
        guard let path = bundle.path(forResource: name, ofType: "bundle") else {
            Ext.log("bundle path error. bundlePath: \(bundle.bundlePath) | bundleName: \(name ?? "")", tag: .error, locationEnabled: false)
            return Bundle.main
        }
        return Bundle(path: path) ?? .main
    }
    
    /// Bundle 文件路径
    /// - Parameters:
    ///   - cls: bundle Class
    ///   - bundleName: bundle 名
    ///   - filePath: bundle 文件路径
    /// - Returns: 文件路径
    static func path(for cls: AnyClass? = nil, bundleName: String, filePath: String) -> String? {
        bundle(for: cls, bundleName: bundleName).path(forResource: filePath, ofType: nil)
    }
    
    /// 获取 Bundle 文件路径
    func filePath(_ filePath: String) -> String? {
        base.path(forResource: filePath, ofType: nil)
    }
}

public extension ExtWrapper where Base == Bundle {
    
    /// Bundle 路径
    func bundle(for path: String) -> Bundle? {
        Bundle(path: base.bundleURL.appendingPathComponent(path).path)
    }
    
    /// 根据图片名字获取 Bundle 中的图片 (如果不存在，再从 mainBundle 获取)
    func image(_ named: String) -> UIImage? {
        UIImage(named: named, in: base, compatibleWith: nil) ?? UIImage(named: named)
    }
    
}
