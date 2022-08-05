//
//  DispatchQueue+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/28.
//

import Foundation

public extension ExtWrapper where Base == DispatchQueue {

    /// 延迟函数
    /// - Parameters:
    ///   - delay: 延迟时间 (单位: 秒 s)
    ///   - handler: 延迟操作
    func after(delay: TimeInterval, handler: @escaping Ext.VoidHandler) {
        base.asyncAfter(deadline: .now() + delay, execute: handler)
    }
}

public extension ExtWrapper where Base == DispatchQueue {
        
    // Reference: https://stackoverflow.com/questions/37886994/dispatch-once-after-the-swift-3-gcd-api-changes
    
    private static var _onceTracker = [String]()

    static func once(file: String = #file,
                     function: String = #function,
                     line: Int = #line,
                     block: () -> Void) {
        let token = "\(file):\(function):\(line)"
        once(token: token, block: block)
    }

    /**
     Executes a block of code, associated with a unique token, only once.  The code is thread safe and will
     only execute the code once even in the presence of multithreaded calls.

     - parameter token: A unique reverse DNS style name such as com.vectorform.<name> or a GUID
     - parameter block: Block to execute once
     */
    static func once(token: String, block: () -> Void) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        guard !_onceTracker.contains(token) else { return }

        _onceTracker.append(token)
        block()
    }
}
