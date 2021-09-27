//
//  Bundle+Ext.swift
//  Ext
//
//  Created by guojian on 2021/9/22.
//

import Foundation

public extension ExtWrapper where Base == Bundle {
    
    static func bundle(for cls: AnyClass? = nil, bundleName: String) -> Bundle {
        var bundle = Bundle.main
        if let cls = cls { bundle = Bundle(for: cls) }
        let bundlePath = bundle.path(forResource: bundleName, ofType: "bundle")
        Ext.debug("bundlePath: \(bundlePath ?? "")", locationEnabled: false)
        guard let path = bundlePath else { return Bundle.main }
        return Bundle(path: path) ?? .main
    }
    
    static func path(for cls: AnyClass? = nil, bundleName: String, fileName: String) -> String? {
        return bundle(for: cls, bundleName: bundleName).path(forResource: fileName, ofType: nil)
    }
    
}
