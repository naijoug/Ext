//
//  FileManager+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/28.
//

import Foundation

public extension ExtWrapper where Base == FileManager {
    /// 文件沙盒路径
    enum SandboxPath {
        /// 主目录
        case home
        /// 临时目录
        case temp
        /// 文档目录
        case document
        /// 库目录
        case library
        /// 缓存目录
        case cache
        
        var path: String {
            switch self {
            case .home: return NSHomeDirectory()
            case .temp: return NSTemporaryDirectory()
            case .document: return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? "\(NSHomeDirectory())/Documents"
            case .library: return NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first ?? "\(NSHomeDirectory())/Library"
            case .cache: return NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first ?? "\(NSHomeDirectory())/Library/Caches"
            }
        }
    }
    /// 文件名类型
    enum FileName {
        /// 当前时间戳
        case timestamp
        /// UUID()
        case uuid
        /// ProcessInfo().globallyUniqueString
        case unique
        /// 自定义名
        case name(String)
        
        public var name: String {
            switch self {
            case .timestamp:    return "\(Date().timeIntervalSince1970)"
            case .uuid:         return UUID().uuidString
            case .unique:       return ProcessInfo().globallyUniqueString
            case .name(let name): return name
            }
        }
    }
    
    /// 创建文件
    /// - Parameters:
    ///   - path: 沙盒目录
    ///   - name: 文件名
    ///   - fileExtension: 文件后缀名
    static func file(for filePath: SandboxPath, fileName: FileName, fileExtension: String = "") -> URL {
        URL(fileURLWithPath: filePath.path, isDirectory: true)
            .appendingPathComponent(fileName.name)
            .appendingPathExtension(fileExtension)
    }
}

public extension ExtWrapper where Base == FileManager {
    
    /// 删除文件
    func remove(_ url: URL?) {
        guard let url = url else { return }
        guard base.fileExists(atPath: url.path) else { return }
        do {
            try base.removeItem(at: url)
        } catch {
            Ext.log("remove \(url.absoluteString) failed.", error: error, tag: .file, locationEnabled: false)
        }
    }
    
    /// 异步删除文件
    /// - Parameters:
    ///   - url: 文件 url
    ///   - handler: 删除完成回调
    func remove(_ url: URL?, handler: @escaping Ext.VoidHandler) {
        DispatchQueue.global().async {
            remove(url)
            DispatchQueue.main.async {
                handler()
            }
        }
    }
    
    /// 如果文件夹不存在，创建
    func createIfNotExists(_ folderUrl: URL?) {
        guard let folderUrl = folderUrl else {
            Ext.log("folder url is nil", tag: .file, locationEnabled: false)
            return
        }
        guard !base.fileExists(atPath: folderUrl.path) else {
            //print("📂 已存在: Url: \(folderUrl.path)")
            return
        }
        do {
            try base.createDirectory(at: folderUrl, withIntermediateDirectories: true, attributes: nil)
        } catch {
            Ext.log("folder create failure | \(folderUrl.path)", error: error, tag: .file, locationEnabled: false)
        }
    }
    
    /// 读取文件中的字符内容
    func read(_ url: URL) -> String? {
        do {
            guard FileManager.default.fileExists(atPath: url.path) else { return nil }
            let data = try Data(contentsOf: url)
            return String(data: data, encoding: .utf8)
        } catch {
            Ext.log("read failed.", error: error, tag: .file, locationEnabled: false)
            return nil
        }
    }
    /// 保存字符串数据到文件
    /// - Parameters:
    ///   - string: 字符串数据
    ///   - url: 保存 url
    func save(_ string: String?, to url: URL?) {
        guard let string = string, let url = url else { return }
        //Ext.log("save data to \(url.path): \(string)")
        let folderUrl = url.deletingLastPathComponent()
        //Ext.log("文件夹路径: \(folderUrl.path)")
        // 目标目录不存在，创建
        createIfNotExists(folderUrl)
        do {
            // 文件存在 -> 删除
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            // 保存数据
            try string.write(to: url, atomically: false, encoding: .utf8)
        } catch {
            Ext.log("save failed.", error: error, tag: .file, locationEnabled: false)
        }
    }
    
    /// 保存字符串数据到文件
    /// - Parameters:
    ///   - string: 字符串数据
    ///   - url: 保存 url
    func save(_ data: Data?, to url: URL?) {
        guard let data = data, let url = url else { return }
        let folderUrl = url.deletingLastPathComponent()
        // 目标目录不存在，创建
        createIfNotExists(folderUrl)
        do {
            // 文件存在 -> 删除
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            // 保存数据
            try data.write(to: url)
        } catch {
            Ext.log("save failure.", error: error, locationEnabled: false)
        }
    }
    
    /// 移动或复制资源到指定位置
    @discardableResult
    func save(_ sourceUrl: URL?, to url: URL?) -> Bool {
        guard let sourceUrl = sourceUrl else {
            Ext.log("源资源 Url 为 nil")
            return false
        }
        guard let url = url else {
            Ext.log("目标资源 Url 为 nil")
            return false
        }
        guard base.fileExists(atPath: sourceUrl.path) else {
            Ext.log("源资源不存在 : \(sourceUrl.path)")
            return false
        }
        let folderUrl = url.deletingLastPathComponent()
        // Ext.log("文件夹路径: \(folderUrl.path)")
        // 目标目录不存在，创建
        createIfNotExists(folderUrl)
        do {
            try base.moveItem(at: sourceUrl, to: url)
            return true
        } catch {
            Ext.log("move failure.", error: error, tag: .file, locationEnabled: false)
            do {
                try base.copyItem(at: sourceUrl, to: url)
                return true
            } catch {
                Ext.log("copy failure.", error: error, tag: .file, locationEnabled: false)
                return false
            }
        }
    }
    
    /// 复制资源到指定位置
    @discardableResult
    func copy(_ sourceUrl: URL?, to url: URL?) -> Bool {
        guard let sourceUrl = sourceUrl else {
            Ext.log("源资源 Url 为 nil")
            return false
        }
        guard let url = url else {
            Ext.log("目标资源 Url 为 nil")
            return false
        }
        guard base.fileExists(atPath: sourceUrl.path) else {
            Ext.log("源资源不存在 : \(sourceUrl.path)")
            return false
        }
        let folderUrl = url.deletingLastPathComponent()
        //Ext.log("文件夹路径: \(folderUrl.path)")
        // 目标目录不存在，创建
        createIfNotExists(folderUrl)
        do {
            try base.copyItem(at: sourceUrl, to: url)
            return true
        } catch {
            Ext.log("copy failure.", error: error, tag: .file, locationEnabled: false)
            return false
        }
    }
}

public extension ExtWrapper where Base == FileManager {
    
}
