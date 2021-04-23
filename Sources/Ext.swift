//
//  Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/26.
//

import Foundation

public final class Ext {}

public extension Ext {
    /// Debug 模式
    static var isDebug: Bool {
        #if DEBUG
            return true
        #else
            return false
        #endif
    }
    
    // 模拟器环境
    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
            return true
        #else
            return false
        #endif
    }
}

public extension Ext {
    /**
     Reference:
        - https://stackoverflow.com/questions/44067192/how-to-handle-void-success-case-with-result-lib-success-failure
     */
    
    /// 无参闭包
    typealias VoidHandler = (() -> Void)
    /// 数据闭包
    typealias DataHandler<T> = ((_ data: T) -> Void)
    /// 函数闭包
    typealias FuncHandler<X, Y> = ((_ x: X) -> Y)
    
    /// 结果闭包
    typealias ResultHandler<T, E: Swift.Error> = ((Result<T, E>) -> Void)
    /// 空结果闭包
    typealias ResultVoidHandler = ResultHandler<Void, Swift.Error>
    /// 数据结果闭包
    typealias ResultDataHandler<T> = ResultHandler<T, Swift.Error>
    
}
extension Ext {
    /**
     错误扩展
     Refrence :
        - https://stackoverflow.com/questions/39176196/how-to-provide-a-localized-description-with-an-error-type-in-swift
     */
    public enum Error: Swift.Error {
        /// Swift error
        case error(_ error: Swift.Error)
        /// 内部处理错误
        case inner(_ message: String?)
        /// 服务器响应错误
        case server(_ message: String?, _ code: Int?)
        /// 网络响应错误
        case response(_ message: String?, _ code: Int?)
    }
}
extension Ext.Error: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .error(let error):
            return error.localizedDescription
        case .inner(let message):
            return "\(message ?? "")"
        case .server(let message, let code):
            var msg = ""
            if let message = message {
                msg += "\(message) *"
            }
            if let code = code {
                msg += " [\(code)]"
            }
            return msg
        case .response(let message, let code):
            var msg = "response error"
            if let code = code {
                msg += " [\(code)]"
            }
            if let message = message {
                msg += " \(message)"
            }
            return msg
        }
    }
}

public extension Ext {
    
    
    /// 代码定位
    /// - Parameters:
    ///   - file: 文件名
    ///   - line: 日志打印行数
    ///   - function: 函数名
    static func codeLocation(file: String = #file, line: Int = #line, function: String = #function) -> String {
        return "\((file as NSString).lastPathComponent):\(line) \t \(function)"
    }
    
    /// Log 级别
    enum LogLevel {
        case info
        case debug
    }
    
    /// 调试函数
    ///
    /// - Parameters:
    ///   - message: 日志消息
    ///   - logEnabled: 是否显示日志
    ///   - toFile: 是否保存日志到文件
    static func debug<T>(_ message: T, level: LogLevel = .info, logEnabled: Bool = true, toFile: Bool = false,
                         file: String = #file, line: Int = #line, function: String = #function) {
        #if DEBUG
        guard logEnabled || toFile else { return }
        
        var log = codeLocation(file: file, line: line, function: function)
        log += " \t \(message)"
        if logEnabled {
            switch level {
            case .info:
                print("Debug \(Date().ext.logTime) \(log)")
            case .debug:
                debugPrint("Debug \(Date().ext.logTime) \(log)")
            }
        }
        guard toFile else { return }
        DispatchQueue.global().async {
            logToFile(log)
        }
        #endif
    }
    
    /// 添加 log 到日志文件
    private static func logToFile(_ message: String) {
        // Reference: https://stackoverflow.com/questions/27327067/append-text-or-data-to-text-file-in-swift
        guard let cachesUrl = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return }
        let logUrl = cachesUrl.appendingPathComponent("Logs", isDirectory: true)
        FileManager.default.ext.createIfNotExists(logUrl)
        let fileName = "\(Date().ext.format(type: .yyyy_MM_dd)).ext.log"
        let logFile = logUrl.appendingPathComponent(fileName)
        
        let timestamp = Date().ext.format(type: .HH_mm_ss_SSS)
        guard let data = (timestamp + ": " + message + "\n").data(using: String.Encoding.utf8) else { return }
        
        if FileManager.default.fileExists(atPath: logFile.path) {
            if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        } else {
            try? data.write(to: logFile, options: .atomicWrite)
        }
    }
}
