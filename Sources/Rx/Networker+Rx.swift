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
                case .success(let data): observer(.success(data))
                }
            }
            return Disposables.create { task.cancel() }
        }
    }
}
