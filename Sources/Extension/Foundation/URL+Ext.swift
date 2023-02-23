//
//  URL+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/28.
//

import Foundation

extension URL: ExtCompatible{}

public extension ExtWrapper where Base == URL {
    /// 根据路径创建 url
    /// - Parameter filePath: 文件路径
    static func url(for filePath: String) -> URL {
        if #available(iOS 16.0, *) {
            return URL(filePath: filePath)
        } else {
            return URL(fileURLWithPath: filePath)
        }
    }
}

public extension ExtWrapper where Base == URL {
    
    /// 移除沙盒前缀的文件路径
    var filePathWithoutSandboxPrefix: String {
        base.path.ext.removePrefix("/private\(NSHomeDirectory())")
    }
    
    // Reference: https://stackoverflow.com/questions/2188469/how-can-i-calculate-the-size-of-a-folder
    
    /// 计算一个文件夹尺寸大小
    var folderAllocatedSize: UInt64 {
        let keys: Set<URLResourceKey> = [.isRegularFileKey, .totalFileAllocatedSizeKey, .fileAllocatedSizeKey]
        guard let enumerator = FileManager.default.enumerator(at: base, includingPropertiesForKeys: Array(keys)) else { return 0 }
        var totalSize: UInt64 = 0
        for item in enumerator {
            guard let fileURL = item as? URL else { continue }
            totalSize += fileURL.ext.fileAllocatedSize
        }
        return totalSize
    }
    
    /// 常规文件尺寸大小
    var fileAllocatedSize: UInt64 {
        do {
            let keys: Set<URLResourceKey> = [.isRegularFileKey, .totalFileAllocatedSizeKey, .fileAllocatedSizeKey]
            let values = try base.resourceValues(forKeys: keys)
            // 常规文件
            guard values.isRegularFile ?? false else { return 0 }
            return UInt64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? 0)
        } catch {
            Ext.log("regularFileAllocatedSize error.", error: error, locationEnabled: false)
            return 0
        }
    }
    
    /// URL (文件或文件夹) 尺寸
    var size: UInt64 {
        do {
            let fullPath = (base.path as NSString).expandingTildeInPath
            let attributes = try FileManager.default.attributesOfItem(atPath: fullPath)
            
            // 如果是文件
            if let type = attributes[FileAttributeKey.type] as? FileAttributeType, type == .typeRegular {
                return attributes[FileAttributeKey.size] as? UInt64 ?? 0
            }
            // 文件夹📂，进行遍历
            let url = URL(fileURLWithPath: fullPath)
            let keys: Set<URLResourceKey> = [.totalFileSizeKey, .fileSizeKey]
            guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: Array(keys), options: [.skipsHiddenFiles]) else {
                return 0
            }
            var totalSize: UInt64 = 0
            for (_, obj) in enumerator.enumerated() {
                guard let fileUrl = obj as? URL, let values = try? fileUrl.resourceValues(forKeys: keys) else { continue }
                let fileSize: UInt64 = (values.isRegularFile ?? false) ? UInt64(values.totalFileSize ?? values.fileSize ?? 0) : 0
                totalSize += fileSize
            }
            return totalSize
        } catch {
            Ext.log("clac size error", error: error, tag: .file, locationEnabled: false)
        }
        return 0
    }
    
    /// 文件大小 (单位: byte)
    var fileSize: Int {
        do {
            let keys: Set<URLResourceKey> = [.isRegularFileKey, .totalFileSizeKey, .fileSizeKey]
            let values = try base.resourceValues(forKeys: keys)
            // 常规文件
            guard values.isRegularFile ?? false else { return 0 }
            return values.totalFileSize ?? values.fileSize ?? 0
        } catch {
            Ext.log("regularFileAllocatedSize error.", error: error, locationEnabled: false)
            return 0
        }
    }
}
