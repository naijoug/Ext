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
    
    /// 处理 result
    /// - Parameters:
    ///   - handler: 抛出 result
    ///   - success: 成功处理
    func handle(_ handler: Ext.ResultDataHandler<Success>? = nil, success: Ext.VoidHandler?) {
        switch self {
        case .failure(let error):
            handler?(.failure(error))
        case .success(let data):
            success?()
            handler?(.success(data))
        }
    }
}
