//
//  DiskCache.swift
//  Ext
//
//  Created by guojian on 2023/2/1.
//

import Foundation

/// 磁盘缓存
public class DiskCache {
    /// 管理的缓存目录
    private let folderURLs: [URL]
    public init(folderURLs: [URL]) {
        self.folderURLs = folderURLs
    }
    
    public enum CacheTime {
        case year(UInt)
        case month(UInt)
        case week(UInt)
        case day(UInt)
        case hour(UInt)
        case minute(UInt)
        
        /// 缓存时长(单位: 秒s)
        var seconds: TimeInterval {
            switch self {
            case .year(let i):      return TimeInterval(i) * 365 * 24 * 60 * 60
            case .month(let i):     return TimeInterval(i) * 30 * 24 * 60 * 60
            case .week(let i):      return TimeInterval(i) * 7 * 24 * 60 * 60
            case .day(let i):       return TimeInterval(i) * 24 * 60 * 60
            case .hour(let i):      return TimeInterval(i) * 60 * 60
            case .minute(let i):    return TimeInterval(i) * 60
            }
        }
    }
    public enum CacheSize {
        case GB(UInt)
        case MB(UInt)
        case KB(UInt)
        
        /// 缓存尺寸(单位: 字节byte)
        var bytes: UInt {
            switch self {
            case .GB(let i): return i * 1024 * 1024 * 1024
            case .MB(let i): return i * 1024 * 1024
            case .KB(let i): return i * 10124
            }
        }
        var title: String {
            switch self {
            case .GB(let i): return "\(i) GB"
            case .MB(let i): return "\(i) MB"
            case .KB(let i): return "\(i) KB"
            }
        }
    }
    
    /// 最大缓存时间 (单位: 秒 默认: 一周)
    public var maxTime: CacheTime = .week(1)
    /// 最大缓存尺寸 (单位: byte 默认: 1GB)
    public var maxSize: CacheSize = .GB(1)
    
    public var logEnabled: Bool = false
    
    /// 磁盘 IO 处理队列
    private let ioQueue = DispatchQueue(label: "ext.diskCache.ioQueue")
    /// 缓存清理状态
    private var isCleaning: Bool = false
    
    /// 清理过期的缓存
    /// - Parameter successHandler: 清理成功
    public func cleanExpired(successHandler: @escaping Ext.VoidHandler) {
        guard !isCleaning else { return }
        isCleaning = true
        ioQueue.sync {
            var resources = self.cacheResrouces.sorted {
                guard let date0 = $0.resourceValues.contentAccessDate,
                      let date1 = $1.resourceValues.contentAccessDate else { return false }
                return date0.compare(date1) == .orderedDescending // 按照访问时间倒序
            }
            // 移除过期时间缓存
            for i in stride(from: resources.count - 1, to: -1, by: -1) {
                let resource = resources[i]
                let filePath = resource.url.ext.filePathWithoutSandboxPrefix
                let values = resource.resourceValues
                Ext.debug("\(i) - \(values.isDirectory ?? false) \t - \((values.contentAccessDate ?? Date()).ext.logTime) - \(values.totalFileAllocatedSize ?? 0) | \(filePath)", logEnabled: logEnabled)
                guard let expiredDate = resource.resourceValues.contentAccessDate?.addingTimeInterval(maxTime.seconds), expiredDate < Date() else { continue }
                Ext.debug("时间过期文件, 移除 \(i) - \(expiredDate.ext.logTime) - \(Date().ext.logTime) | \(filePath)", logEnabled: logEnabled)
                try? FileManager.default.removeItem(at: resource.url)
                resources.remove(at: i)
            }
            var totalSize = UInt(resources.compactMap({ $0.resourceValues.totalFileAllocatedSize ?? 0 }).reduce(0, +))
            Ext.debug("移除过期时间完成: \(resources.count) | 已缓存空间: \(totalSize) = \(Double(totalSize)/1024/1024) mb | 最大缓存空间 = \(maxSize.title)", logEnabled: logEnabled)
            if totalSize > maxSize.bytes {
                for i in stride(from: resources.count - 1, to: -1, by: -1) {
                    let resource = resources[i]
                    let filePath = resource.url.ext.filePathWithoutSandboxPrefix
                    let values = resource.resourceValues
                    let fileSize = UInt(values.totalFileAllocatedSize ?? 0)
                    Ext.debug("移除 \(i) -\(fileSize) - \(values.isDirectory ?? false) \t - \(values.contentAccessDate ?? Date()) - \(values.totalFileAllocatedSize ?? 0) | \(filePath)", logEnabled: logEnabled)
                    try? FileManager.default.removeItem(at: resource.url)
                    resources.remove(at: i)
                    totalSize -= fileSize
                    guard totalSize <= maxSize.bytes else { continue }
                    break
                }
            }
            
            Ext.debug("缓存移除完成. 缓存尺寸: \(totalSize) = \(Double(totalSize)/1024/1024) mb", logEnabled: logEnabled)
            self.isCleaning = false
            DispatchQueue.main.async {
                successHandler()
            }
        }
    }
    
    /// 缓存资源
    private struct CacheResource {
        let url: URL
        let resourceValues: URLResourceValues
    }
    /// 获取缓存资源
    private var cacheResrouces: [CacheResource] {
        var resources = [CacheResource]()
        let keys: Set<URLResourceKey> = [.isDirectoryKey, .contentAccessDateKey, .totalFileAllocatedSizeKey]
        for folderURL in folderURLs {
            guard let enumerator = FileManager.default.enumerator(at: folderURL, includingPropertiesForKeys: Array(keys)) else {
                Ext.debug("enumerator is nil. \(folderURL)", logEnabled: logEnabled)
                continue
            }
            for (index, value) in enumerator.enumerated() {
                Ext.debug("\(index) - \(value)", logEnabled: logEnabled)
                guard let url = value as? URL, let resourceValues = try? url.resourceValues(forKeys: keys) else { continue }
                resources.append(CacheResource(url: url, resourceValues: resourceValues))
            }
        }
        return resources
    }
}
