//
//  Sugar.swift
//  Ext
//
//  Created by guojian on 2022/1/11.
//

import Foundation

/**
 Reference
    - https://github.com/devxoul/Then
 */

/// swift 语法糖
public protocol Sugar {}

public extension Sugar {
    /// 初始化
    func setup(_ handler: (Self) throws -> Void) rethrows -> Self {
        try handler(self)
        return self
    }
    
    /// 拷贝
    func copy(_ handler: (inout Self) throws -> Void) rethrows -> Self {
        var copy = self
        try handler(&copy)
        return copy
    }
    
    /// 完成操作
    func todo(_ handler: (Self) throws -> Void) rethrows {
        try handler(self)
    }
}

extension NSObject: Sugar {}
extension Dictionary: Sugar {}
extension Array: Sugar {}
extension Set: Sugar {}
