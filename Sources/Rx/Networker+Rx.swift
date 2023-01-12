//
//  Networker+Rx.swift
//  Ext
//
//  Created by guojian on 2023/1/9.
//

import Foundation
import RxSwift

public extension Reactive where Base == Networker {
    /// 请求网络数据
    /// - Parameters:
    ///   - queue: 数据响应所在的队列 (默认: 主队列)
    ///   - request: 请求体
    ///   - requestLog: 请求日志
    func data(queue: DispatchQueue = .main, request: URLRequest, requestLog: String? = nil) -> Single<Ext.DataResponse> {
        Single.create { observer in
            let task = base.data(queue: queue, request: request) { result in
                switch result {
                case .failure(let error): observer(.failure(error))
                case .success(let resp): observer(.success(resp))
                }
            }
            return Disposables.create { task.cancel() }
        }
    }
}

public extension Reactive where Base == Networker {
    /// 数据请求响应
    static func response(queue: DispatchQueue = .main, request: Requestable) -> Single<Ext.DataResponse> {
        Single.create { observer in
            let task = Base.ext.response(queue: queue, request: request) { result in
                switch result {
                case .failure(let error): observer(.failure(error))
                case .success(let resp): observer(.success(resp))
                }
            }
            return Disposables.create { task?.cancel() }
        }
    }
    
    /// 数据请求
    static func data(queue: DispatchQueue = .main, request: Requestable) -> Single<Data> {
        response(queue: queue, request: request).map { $0.data }
    }
}

/// Rx 数据请求协议
public typealias ExtRxRequestable = Requestable & ReactiveCompatible

public extension Reactive where Base: ExtRxRequestable {
    /// 数据请求响应
    func response(queue: DispatchQueue = .main) -> Single<Ext.DataResponse> {
        Networker.rx.response(queue: queue, request: base)
    }
    
    /// 数据请求
    func data(queue: DispatchQueue = .main) -> Single<Data> {
        response(queue: queue).map { $0.data }
    }
}
