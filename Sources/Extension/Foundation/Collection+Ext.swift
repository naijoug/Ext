//
//  Collection+Ext.swift
//  Ext
//
//  Created by guojian on 2022/2/17.
//

import Foundation

public extension Array where Element: Equatable {
    
    /// 指定元素的下一个元素
    /// - Parameter element: 指定元素
    /// - Parameter loop: 是否循环 (最后一个元素的下一个: 第一个)
    /// - Returns: 下一个元素
    func next(_ element: Element, loop: Bool = false) -> Element? {
        guard let index = firstIndex(of: element) else { return nil }
        return next(index, loop: loop)
    }
    
    /// 指定索引的下一个元素
    /// - Parameter index: 指定索引
    /// - Parameter loop: 是否循环 (最后一个元素的下一个: 第一个)
    /// - Returns: 下一个元素
    func next(_ index: Int, loop: Bool = false) -> Element? {
        guard count > 0, 0 <= index, index < count else { return nil }
        var nextIndex = index + 1
        guard loop else {
            guard 0 <= nextIndex, nextIndex < count else { return nil }
            Ext.debug("\(index) -> \(nextIndex)")
            return self[nextIndex]
        }
        nextIndex = nextIndex % count
        Ext.debug("loop: \(index) -> \(nextIndex)")
        return self[nextIndex]
    }
    
    /// 指定索引的上一个元素
    /// - Parameter element: 指定元素
    /// - Parameter loop: 是否循环 (第一个元素的上一个: 最后一个)
    /// - Returns: 上一个元素
    func pre(_ element: Element, loop: Bool = false) -> Element? {
        guard let index = firstIndex(of: element) else { return nil }
        return pre(index, loop: loop)
    }
    
    /// 指定索引的上一个元素
    /// - Parameter index: 指定索引
    /// - Parameter loop: 是否循环 (第一个元素的上一个: 最后一个)
    /// - Returns: 上一个元素
    func pre(_ index: Int, loop: Bool = false) -> Element? {
        guard count > 0, 0 <= index, index < count else { return nil }
        var preIndex = index - 1
        guard loop else {
            guard 0 <= preIndex, preIndex < count else { return nil }
            Ext.debug("\(index) -> \(preIndex)")
            return self[preIndex]
        }
        preIndex = (count + preIndex) % count
        Ext.debug("loop: \(index) -> \(preIndex)")
        return self[preIndex]
    }
}
