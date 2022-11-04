//
//  Result+Ext.swift
//  Ext
//
//  Created by guojian on 2022/7/28.
//

import Foundation

public extension Result {
    /// 是否成功
    var isSucceeded: Bool {
        switch self {
        case .failure: return false
        case .success: return true
        }
    }
    
    /// 转化为 void result
    func toVoid() -> Result<Void, Failure> {
        switch self {
        case .failure(let error): return .failure(error)
        case .success: return .success(())
        }
    }
}
