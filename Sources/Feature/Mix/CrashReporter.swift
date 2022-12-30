//
//  CrashReporter.swift
//  Ext
//
//  Created by naijoug on 2022/3/30.
//

import Foundation
import SystemConfiguration

/**
 Reference:
    - https://developer.apple.com/documentation/xcode/understanding-the-exception-types-in-a-crash-report
    - [Implementing Your Own Crash Reporter](https://developer.apple.com/forums/thread/113742)
    - [In Swift, how do I capture every error and send it to a webservice?](https://developer.apple.com/forums/thread/68031)
    - https://github.com/MerchV/iOSCrashReporter
    - https://github.com/xiaoyi6409/XYCrashManager
 */

public final class CrashReporter {
    public static let shared = CrashReporter()
    private init() {}
    
    private var reportHandler: (([String: Any], Ext.ResultVoidHandler?) -> Void)?
    
    /// 初始化
    /// - Parameters:
    ///   - crashURL: crash 文件 URL
    ///   - reportHandler: 报告 crash 回调
    public func setup(_ reportHandler: @escaping ([String: Any], Ext.ResultVoidHandler?) -> Void) {
        self.reportHandler = reportHandler
        
        registerExceptionHandler()
        registerSignalHandler()
        
        read { crash in
            guard let crash = crash else { return }
            Ext.debug("last crash: \(crash)", tag: .bang, locationEnabled: false)
            reportHandler(crash) { result in
                switch result {
                case .failure: ()
                case .success:
                    Ext.debug("after report success, clear crash file.", tag: .clean, locationEnabled: false)
                    CrashReporter.shared.clear()
                }
            }
        }
    }
}

private extension CrashReporter {
    
    var crashURL: URL? {
        guard let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first else { return nil }
        return URL(fileURLWithPath: path).appendingPathComponent("ext.crash.json")
    }
    
    /// 保存 crash 内容
    func save(_ crash: [String: Any]) {
        guard let crashUrl = crashURL else { return }
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss SSS"
        var crash = crash
        crash["timestamp"] = date.timeIntervalSince1970
        crash["time"] = formatter.string(from: date)
        DispatchQueue.global().async {
            let crashString = Ext.JSON.toString(jsonObject: crash, prettyPrinted: true) ?? "\(crash)"
            FileManager.default.ext.save(crashString, to: crashUrl)
        }
    }
    /// 读取上次 crash 内容
    func read(_ handler: @escaping Ext.DataHandler<[String: Any]?>) {
        guard let crashUrl = crashURL else {
            handler(nil)
            return
        }
        DispatchQueue.global().async {
            guard let crashString = FileManager.default.ext.read(crashUrl) else {
                handler(nil)
                return
            }
            let crash = Ext.JSON.toJSONObject(crashString) as? [String: Any]
            DispatchQueue.main.async {
                handler(crash)
            }
        }
    }
    /// 清理 crash 内容
    func clear() {
        FileManager.default.ext.remove(crashURL)
    }
}

private extension CrashReporter {
    /// 注册异常处理
    func registerExceptionHandler() {
        NSSetUncaughtExceptionHandler { (exception: NSException) in
            let crash = ["exception": [
                "name": "\(exception.name)",
                "reason": "\(exception.reason ?? "")",
                "stackSymbols": exception.callStackSymbols,
                "statkReturnAddress": exception.callStackReturnAddresses
            ]]
            Ext.debug(crash, tag: .bang)
            CrashReporter.shared.save(crash)
        }
    }
    
    /// 注册信号处理
    func registerSignalHandler() {
        let sigs: [Int32] = [SIGTRAP, SIGABRT, SIGKILL, SIGSEGV, SIGBUS]
        for sig in sigs {
            signal(sig) { (sig: Int32) in
                let sigDict: [Int32: String] = [
                    SIGTRAP:    "SIGTRAP",
                    SIGABRT:    "SIGABRT",
                    SIGKILL:    "SIGKILL",
                    SIGSEGV:    "SIGSEGV",
                    SIGBUS:     "SIGBUS"
                ]
                
                let crash = ["signal": [
                    "name": "\(sigDict[sig] ?? "\(sig)")",
                    "stackSymbols": Thread.callStackSymbols
                ]]
                Ext.debug(crash, tag: .bang)
                CrashReporter.shared.save(crash)
                
                exit(sig)
            }
        }
    }
}
