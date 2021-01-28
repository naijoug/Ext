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
    
    /// code location
    static func codeLocation(file: String = #file,
                             line: Int = #line,
                             function: String = #function) -> String {
        let fileName = (file as NSString).lastPathComponent
        return "\(fileName):\(line) \t \(function)"
    }
    
    /// debug log
    ///
    /// - Parameters:
    ///   - message: log message
    ///   - logEnabled: print log
    ///   - fileEnabled: print file log
    ///   - file: file
    ///   - line: log line
    ///   - function: log function
    static func debug(_ message: String?,
                      logEnabled: Bool = true,
                      fileEnabled: Bool = false,
                      file: String = #file,
                      line: Int = #line,
                      function: String = #function) {
        let log = codeLocation(file: file, line: line, function: function) + " | \(message ?? "")"
        if fileEnabled { // 写入文件
            DispatchQueue.global().async {
                logToFile(log)
            }
        }
        guard isDebug, logEnabled else { return }
        print("Debug \(Date().ext.format(name: .yyyy_MM_dd_HH_mm_ss_SSS)) | \(log)")
    }
    
    /// 添加 log 到日志文件
    private static func logToFile(_ message: String) {
        // Reference: https://stackoverflow.com/questions/27327067/append-text-or-data-to-text-file-in-swift
        guard let cachesUrl = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return }
        let logFolder = cachesUrl.appendingPathComponent("Logs", isDirectory: true)
        FileManager.default.ext.createIfNotExists(logFolder)
        let fileName = "\(Date().ext.format(name: .yyyy_MM_dd)).ext.log"
        let logFile = logFolder.appendingPathComponent(fileName)
        
        let timestamp = Date().ext.format(name: .HH_mm_ss_SSS)
        guard let data = ("\(timestamp): \(timestamp)\n").data(using: String.Encoding.utf8) else { return }
        
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
