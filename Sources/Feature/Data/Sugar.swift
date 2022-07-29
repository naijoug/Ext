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
    @inlinable
    func setup(_ handler: (Self) throws -> Void) rethrows -> Self {
        try handler(self)
        return self
    }
}

extension NSObject: Sugar {}
