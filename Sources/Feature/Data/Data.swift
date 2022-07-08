//
//  Data.swift
//  Ext
//
//  Created by guojian on 2021/11/5.
//

import Foundation


/**
 Reference:
    - https://stackoverflow.com/questions/24242629/implementing-copy-in-swift
 */

/// 数据拷贝协议
public protocol Copyable {
    init(_ instance: Self)
}
public extension Copyable {
    /// Copy
    func copy() -> Self {
        Self.init(self)
    }
}

/// 数据刷新协议
public protocol Refreshable {
    func refresh()
}

/// 数据缓存协议
public protocol Cacheable {
    func cache()
}
