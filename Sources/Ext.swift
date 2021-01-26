//
//  Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/26.
//

import Foundation

public final class Ext {}


public extension Ext {
    
    /**
     Reference:
        - https://stackoverflow.com/questions/44067192/how-to-handle-void-success-case-with-result-lib-success-failure
     */
    
    /// no data closure
    typealias VoidHandler = (() -> Void)
    /// data closure
    typealias DataHandler<T> = ((_ data: T) -> Void)
    
    /// Result closure
    typealias ResultHandler<T, E: Swift.Error> = ((Result<T, E>) -> Void)
    /// Result data closure
    typealias ResultDataHandler<T> = ResultHandler<T, Swift.Error>
    /// Result no data closure
    typealias ResultVoidHandler = ResultHandler<Void, Swift.Error>
    
}

extension Ext {
    
    /**
     Reference :
        - https://stackoverflow.com/questions/39176196/how-to-provide-a-localized-description-with-an-error-type-in-swift
     */
    public enum Error: Swift.Error {
        /// inner error
        case inner(_ message: String?)
        /// response error
        case response(_ message: String?, code: Int?)
    }
}
extension Ext.Error: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .inner(let message):
            return "inner error: \(message ?? "")"
        case .response(let message, code: let code):
            return "response error \(code ?? -110): \(message ?? "")"
        }
    }
}
