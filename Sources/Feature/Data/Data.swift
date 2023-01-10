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

/// 数据可拷贝协议
public protocol DataCopyable {
    init(_ instance: Self)
}
public extension DataCopyable {
    /// 拷贝数据
    func copy() -> Self {
        Self.init(self)
    }
}

/// 数据可刷新协议
public protocol DataRefreshable {
    /// 刷新数据
    func refresh()
}

/// 数据可缓存协议
public protocol DataCacheable {
    /// 缓存数据
    func cache()
}

/// 数据日志协议
public protocol DataLogable {
    /// 数据日志
    var log: String { get }
}

/// 数据可绑定协议
public protocol DataBindable {
    associatedtype Item
    /// 数据绑定
    func bind(_ item: Item)
}
