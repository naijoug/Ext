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

public protocol Copyable {
    init(_ instance: Self)
}
public extension Copyable {
    /// Copy
    func copy() -> Self {
        Self.init(self)
    }
}
