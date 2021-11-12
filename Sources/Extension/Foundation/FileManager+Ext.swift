//
//  FileManager+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/28.
//

import Foundation

public extension ExtWrapper where Base == FileManager {
    
    /// 删除文件
    func remove(_ url: URL?) {
        guard let url = url else { return }
        guard base.fileExists(atPath: url.path) else { return }
        do {
            try base.removeItem(at: url)
        } catch {
            Ext.debug("remove \(url.absoluteString) failure.", error: error, tag: .file, locationEnabled: false)
        }
    }
    
    /// 如果文件夹不存在，创建
    func createIfNotExists(_ folderUrl: URL?) {
        guard let folderUrl = folderUrl else {
            Ext.debug("folder url is nil", tag: .file, locationEnabled: false)
            return
        }
        guard !base.fileExists(atPath: folderUrl.path) else {
            //print("📂 已存在: Url: \(folderUrl.path)")
            return
        }
        do {
            try base.createDirectory(at: folderUrl, withIntermediateDirectories: true, attributes: nil)
        } catch {
            Ext.debug("folder create failure | \(folderUrl.path)", error: error, tag: .file, locationEnabled: false)
        }
    }
    
    /// 保存字符串数据到文件
    /// - Parameters:
    ///   - string: 字符串数据
    ///   - url: 保存 url
    func save(_ string: String?, to url: URL?) {
        guard let string = string, let url = url else { return }
        //Ext.debug("save data to \(url.path): \(string)")
        let folderUrl = url.deletingLastPathComponent()
        //Ext.debug("文件夹路径: \(folderUrl.path)")
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
            Ext.debug("save failure.", error: error, tag: .file, locationEnabled: false)
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
            Ext.debug("save failure.", error: error, locationEnabled: false)
        }
    }
    
    /// 移动或复制资源到指定位置
    @discardableResult
    func save(_ sourceUrl: URL?, to url: URL?) -> Bool {
        guard let sourceUrl = sourceUrl else {
            Ext.debug("源资源 Url 为 nil")
            return false
        }
        guard let url = url else {
            Ext.debug("目标资源 Url 为 nil")
            return false
        }
        guard base.fileExists(atPath: sourceUrl.path) else {
            Ext.debug("源资源不存在 : \(sourceUrl.path)")
            return false
        }
        let folderUrl = url.deletingLastPathComponent()
        // Ext.debug("文件夹路径: \(folderUrl.path)")
        // 目标目录不存在，创建
        createIfNotExists(folderUrl)
        do {
            try base.moveItem(at: sourceUrl, to: url)
            return true
        } catch {
            Ext.debug("move failure.", error: error, tag: .file, locationEnabled: false)
            do {
                try base.copyItem(at: sourceUrl, to: url)
                return true
            } catch {
                Ext.debug("copy failure.", error: error, tag: .file, locationEnabled: false)
                return false
            }
        }
    }
    
    /// 复制资源到指定位置
    @discardableResult
    func copy(_ sourceUrl: URL?, to url: URL?) -> Bool {
        guard let sourceUrl = sourceUrl else {
            Ext.debug("源资源 Url 为 nil")
            return false
        }
        guard let url = url else {
            Ext.debug("目标资源 Url 为 nil")
            return false
        }
        guard base.fileExists(atPath: sourceUrl.path) else {
            Ext.debug("源资源不存在 : \(sourceUrl.path)")
            return false
        }
        let folderUrl = url.deletingLastPathComponent()
        //Ext.debug("文件夹路径: \(folderUrl.path)")
        // 目标目录不存在，创建
        createIfNotExists(folderUrl)
        do {
            try base.copyItem(at: sourceUrl, to: url)
            return true
        } catch {
            Ext.debug("copy failure.", error: error, tag: .file, locationEnabled: false)
            return false
        }
    }
}
