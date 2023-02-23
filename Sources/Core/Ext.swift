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

public extension Ext {
    
    /// Ext 全局 log 开关
    static var logEnabled: Bool = true
    
    /// 代码定位
    /// - Parameters:
    ///   - file: 文件名
    ///   - line: 日志打印行数
    ///   - function: 函数名
    static func codeLocation(file: String = #file, line: Int = #line, function: String = #function) -> String {
        "\((file as NSString).lastPathComponent):\(line) \t\(function)"
    }
    
    /// 调试日志
    ///
    /// - Parameters:
    ///   - message: 日志消息
    ///   - error: 错误信息
    ///   - tag: 日志标记
    ///   - logEnabled: 是否显示日志
    ///   - locationEnabled: 是否打印代码定位日志
    static func log(_ message: Any,
                    error: Swift.Error? = nil,
                    tag: Tag = .normal,
                    logEnabled: Bool = true,
                    locationEnabled: Bool = true,
                    file: String = #file, line: Int = #line, function: String = #function) {
        /**
         Reference:
            - https://swift.gg/2016/08/03/swift-prettify-your-print-statements-pt-1/
            - https://swift.gg/2016/09/12/default-arguments-in-protocols/
         */
        #if DEBUG
        guard logEnabled else { return }
        logToTerminal(
            messageToLog(message, error: error, tag: tag, locationEnabled: locationEnabled, file: file, line: line, function: function)
        )
        #endif
    }
    
    ///   - logToFileEnabled: 是否保存日志到文件
    static func log(_ message: Any,
                    error: Swift.Error? = nil,
                    tag: Tag = .normal,
                    logEnabled: Bool = true,
                    locationEnabled: Bool = true,
                    logToFileEnabled: Bool,
                    file: String = #file, line: Int = #line, function: String = #function) {
        log(message, error: error, tag: tag, logEnabled: logEnabled, locationEnabled: locationEnabled, file: file, line: line, function: function)
        guard logToFileEnabled else { return }
        logToFile(
            messageToLog(message, error: error, tag: tag, locationEnabled: locationEnabled, file: file, line: line, function: function)
        )
    }
    
}
private extension Ext {
    
    /// 日志内容
    static func messageToLog(_ message: Any,
                             error: Swift.Error? = nil,
                             tag: Tag = .normal,
                             locationEnabled: Bool = true,
                             file: String = #file, line: Int = #line, function: String = #function) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss SSS"
        var log = "LOG \(formatter.string(from: Date())) \(tag)"
        if locationEnabled { log += " 【\(codeLocation(file: file, line: line, function: function))】" }
        log += " \(message)"
        if let error = error { log += " \(Tag.error) \(error)" }
        return log
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

// MARK: - Tag

public extension Ext {
    /// 标记符号
    enum Tag {
        case normal
        case success
        case failure
        case warning
        case error
        
        case video
        case audio
        case image
        
        case play
        case pause
        case replay
        case stop
        
        case begin
        case end
        
        case debug
        case programmer
        
        case ok
        case pin
        case sos
        case fix
        case bang
        case fire
        case file
        case clean
        case store
        case timer
        case bingo
        case watch
        case target
        case launch
        case network
        case recycle
        case perfect
        case champion
        case basketball
        case notification
        
        /// 自定义符号
        case custom(_ token: String)
    }
}

extension Ext.Tag: CustomStringConvertible {
    public var description: String {
        switch self {
        case .normal:           return "##"
        case .success:          return "✅"
        case .failure:          return "🚫"
        case .warning:          return "⚠️"
        case .error:            return "❌"
        
        case .video:            return "🎥"
        case .audio:            return "🎙"
        case .image:            return "🌌"
        
        case .play:             return "▶️"
        case .pause:            return "⏸"
        case .replay:           return "🔄"
        case .stop:             return "⏹"
            
        case .begin:            return "🛫"
        case .end:              return "🛬"
            
        case .debug:            return "🪲"
        case .programmer:       return "🐵"
            
        case .ok:               return "👌"
        case .pin:              return "📌"
        case .sos:              return "🆘"
        case .fix:              return "🛠"
        case .bang:             return "💥"
        case .fire:             return "🔥"
        case .file:             return "📚"
        case .clean:            return "🧹"
        case .store:            return "📦"
        case .timer:            return "⏰"
        case .bingo:            return "🎉"
        case .watch:            return "👀"
        case .target:           return "🎯"
        case .launch:           return "🚀"
        case .network:          return "🌏"
        case .recycle:          return "♻️"
        case .perfect:          return "💯"
        case .champion:         return "🏆"
        case .basketball:       return "🏀"
        case .notification:     return "📣"
        
        case .custom(let token): return token
        }
    }
}

public protocol ExtLogable: ExtCompatible {
    /// 是否启用日志开关
    var logEnabled: Bool { get }
}
public extension ExtLogable {
    /// 默认开启日志
    var logEnabled: Bool { true }
}

public extension ExtWrapper where Base: ExtLogable {
    func log(_ message: Any,
             error: Swift.Error? = nil,
             logEnabled: Bool = true,
             locationEnabled: Bool = true,
             file: String = #file, line: Int = #line, function: String = #function) {
        Ext.log(message, error: error, logEnabled: logEnabled && base.logEnabled,
                locationEnabled: locationEnabled, file: file, line: line, function: function)
    }
}
