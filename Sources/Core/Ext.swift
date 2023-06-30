//
//  Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/26.
//

import Foundation

public enum Ext {}

public extension Ext {
    /// Debug 模式
    static var isDebug: Bool {
        #if DEBUG
            return true
        #else
            return false
        #endif
    }
    
    /**
     Reference
        - https://stackoverflow.com/questions/24869481/how-to-detect-if-app-is-being-built-for-device-or-simulator-in-swift
     */
    
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
    typealias VoidHandler = () -> Void
    /// 数据闭包
    typealias DataHandler<T> = (_ data: T) -> Void
    /// 函数闭包
    typealias FuncHandler<X, Y> = (_ x: X) -> Y
    
    /// 结果闭包
    typealias ResultHandler<T, E: Swift.Error> = ((Swift.Result<T, E>) -> Void)
    /// 空结果闭包
    typealias ResultVoidHandler = ResultHandler<Void, Swift.Error>
    /// 数据结果闭包
    typealias ResultDataHandler<T> = ResultHandler<T, Swift.Error>
    
}

extension Ext {
    /**
     Reference :
        - https://stackoverflow.com/questions/39176196/how-to-provide-a-localized-description-with-an-error-type-in-swift
     */
    public enum Error: Swift.Error {
        /// JSON 序列化错误
        case jsonSerializationError(_ error: Swift.Error)
        /// JSON 反序列化错误
        case jsonDeserializationError(error: Swift.Error)
        /// JSON 编码错误
        case jsonEncodeError(error: Swift.Error)
        /// JSON 解码错误
        case jsonDecodeError(error: Swift.Error)
        
        /// Swift 错误
        case error(_ error: Swift.Error)
        /// 内部处理错误
        case inner(_ message: String?, code: Int = -110)
    }
}
extension Ext.Error: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .jsonSerializationError(let error):    return "json serialization error: \(error.localizedDescription)"
        case .jsonDeserializationError(let error):  return "json deserialization error: \(error.localizedDescription)"
        case .jsonEncodeError(let error):           return "json encode error: \(error.localizedDescription)"
        case .jsonDecodeError(let error):           return "json decode error: \(error.localizedDescription)"
        case .error(let error):                     return error.localizedDescription
        case .inner(let message, _):                return message
        }
    }
}

// MARK: - Log

public extension Ext {
    /// 日志级别
    enum LogLevel: Int {
        /// 关闭日志
        case off
        /// 日志信息
        case info
        /// 日志调试信息(包含日志代码位置)
        case debug
        
        /// 默认日志级别
        public static var `default`: LogLevel = .debug
    }
    /// 日志内容配置
    struct LogConfig {
        /// 日志标记 (默认: ##)
        public var tag: String
        /// 是否显示日期信息 (默认: 开启)
        public var dated: Bool
        /// 是否显示代码定位信息 (默认: 开启)
        public var located: Bool
        
        public init(tag: String = "##", dated: Bool = true, located: Bool = true) {
            self.tag = tag
            self.dated = dated
            self.located = located
        }
    }
}

public protocol ExtLogable: ExtCompatible {
    /// 日志级别
    var logLevel: Ext.LogLevel { get }
    /// 日志配置
    var logConfig: Ext.LogConfig { get }
}
public extension ExtLogable {
    /// 默认日志级别
    var logLevel: Ext.LogLevel { .default }
    /// 默认日志配置
    var logConfig: Ext.LogConfig { .init() }
}

public extension ExtWrapper where Base: ExtLogable {
    
    /// 根据日志开关输出
    /// - Parameters:
    ///   - message: 日志消息
    ///   - error: 错误消息
    ///   - logLevel: 日志级别
    func log(_ message: Any, error: Swift.Error? = nil,
             level: Ext.LogLevel? = nil, config: Ext.LogConfig? = nil,
             file: String = #file, line: Int = #line, function: String = #function) {
        Ext.log(message, error: error,
                level: level ?? base.logLevel, config: config ?? base.logConfig,
                file: file, line: line, function: function)
    }
}

extension Ext {
    static let inner = Inner()
    
    /// 内部类
    struct Inner: ExtLogable {
        var logLevel: Ext.LogLevel = .info
        var logConfig: Ext.LogConfig = .init(located: false)
    }
}

public protocol ExtInnerLogable: ExtLogable {}
public extension ExtInnerLogable {
    var logLevel: Ext.LogLevel { Ext.inner.logLevel }
    var logConfig: Ext.LogConfig { Ext.inner.logConfig }
}

public extension Ext {
    /// 日志记录
    ///
    /// - Parameters:
    ///   - message: 日志消息
    ///   - error: 错误信息
    ///   - level: 日志级别
    static func log(_ message: Any, error: Swift.Error? = nil,
                    level: Ext.LogLevel = .default, config: Ext.LogConfig = .init(),
                    file: String = #file, line: Int = #line, function: String = #function) {
        /**
         Reference:
            - https://swift.gg/2016/08/03/swift-prettify-your-print-statements-pt-1/
            - https://swift.gg/2016/09/12/default-arguments-in-protocols/
         */
        #if DEBUG
        guard level != .off else { return }
        logToTerminal(
            messageToLog(message, error: error, config: config, file: file, line: line, function: function)
        )
        #endif
    }
    
    ///   - logToFileEnabled: 是否保存日志到文件
    static func log(_ message: Any, error: Swift.Error? = nil,
                    level: Ext.LogLevel = .default, config: Ext.LogConfig = .init(),
                    logToFileEnabled: Bool,
                    file: String = #file, line: Int = #line, function: String = #function) {
        log(message, error: error, level: level, config: config, file: file, line: line, function: function)
        guard logToFileEnabled else { return }
        logToFile(
            messageToLog(message, error: error, config: config, file: file, line: line, function: function)
        )
    }
}
private extension Ext {
    
    /// 日志内容
    static func messageToLog(_ message: Any, error: Swift.Error? = nil, config: Ext.LogConfig,
                             file: String = #file, line: Int = #line, function: String = #function) -> String {
        var log = "LOG \(config.tag)"
        if config.dated {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss SSS"
            log += " \(formatter.string(from: Date()))"
        }
        if config.located {
            log += " 【\(codeLocation(file: file, line: line, function: function))】"
        }
        log += " \(message)"
        if let error = error {
            log += " ❌ \(error)"
        }
        return log
    }
    /// 代码定位
    /// - Parameters:
    ///   - file: 文件名
    ///   - line: 日志打印行数
    ///   - function: 函数名
    private static func codeLocation(file: String = #file, line: Int = #line, function: String = #function) -> String {
        "\((file as NSString).lastPathComponent):\(line) \t\(function)"
    }
    
    /// 日志队列
    private static let logQueue = DispatchQueue(label: "ext.log.queue")
    
    /// 输出日志到终端
    static func logToTerminal(_ log: String) {
        logQueue.async {
            Swift.print(log)
        }
    }
    
    /// 添加 log 到日志文件
    static func logToFile(_ log: String) {
        logQueue.async {
            // Reference: https://stackoverflow.com/questions/27327067/append-text-or-data-to-text-file-in-swift
            guard let cachesUrl = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return }
            let logFolder = cachesUrl.appendingPathComponent("Logs", isDirectory: true)
            if !FileManager.default.fileExists(atPath: logFolder.path) {
                try? FileManager.default.createDirectory(atPath: logFolder.path, withIntermediateDirectories: true)
            }
            let date = Date()
            let formatter = DateFormatter()
            
            formatter.dateFormat = "yyyy-MM-dd"
            let logFile = logFolder.appendingPathComponent("Ext_\(formatter.string(from: date)).log")
            
            formatter.dateFormat = "HH:mm:ss SSS"
            guard let data = (formatter.string(from: date) + " | " + log + "\n").data(using: String.Encoding.utf8) else { return }
            
            if FileManager.default.fileExists(atPath: logFile.path) {
                if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: logFile)
            }
        }
    }
}
