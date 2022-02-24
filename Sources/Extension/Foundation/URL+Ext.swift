//
//  URL+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/28.
//

import Foundation

extension URL: ExtCompatible{}

public extension ExtWrapper where Base == URL {
    
    // Reference: https://stackoverflow.com/questions/2188469/how-can-i-calculate-the-size-of-a-folder
    
    fileprivate var allocatedSizeResourceKeys: Set<URLResourceKey> {
        return [.isRegularFileKey, .fileAllocatedSizeKey, .totalFileAllocatedSizeKey]
    }
    
    /// 计算一个文件夹尺寸大小
    var folderAllocatedSize: UInt64 {
        guard let enumerator = FileManager.default.enumerator(at: base, includingPropertiesForKeys: Array(allocatedSizeResourceKeys), options: [], errorHandler: nil) else {
            return 0
        }
        var accumulatedSize: UInt64 = 0
        for item in enumerator {
            guard let fileUrl = item as? URL else {
                continue
            }
            accumulatedSize += fileUrl.ext.regularFileAllocatedSize
        }
        return accumulatedSize
    }
    
    /// 常规文件尺寸大小
    var regularFileAllocatedSize: UInt64 {
        do {
            let resourceValues = try base.resourceValues(forKeys: allocatedSizeResourceKeys)
            // 常规文件
            guard resourceValues.isRegularFile ?? false else {
                return 0
            }
            return UInt64(resourceValues.totalFileAllocatedSize ?? resourceValues.fileAllocatedSize ?? 0)
        } catch {
            Ext.debug("regularFileAllocatedSize error.", error: error, locationEnabled: false)
        }
        return 0
    }
    
    /// URL (文件或文件夹) 尺寸
    var size: UInt64 {
        do {
            let fullPath = (base.path as NSString).expandingTildeInPath
            let itemAttributes = try FileManager.default.attributesOfItem(atPath: fullPath)
            
            // 如果是文件
            if let type = itemAttributes[FileAttributeKey.type] as? FileAttributeType, type == .typeRegular {
                return itemAttributes[FileAttributeKey.size] as? UInt64 ?? 0
            }
            // 文件夹📂，进行遍历
            let url = URL(fileURLWithPath: fullPath)
            guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles], errorHandler: nil) else {
                return 0
            }
            var total: UInt64 = 0
            for (_, obj) in enumerator.enumerated() {
                guard let fileUrl = obj as? NSURL else { continue }
                var fileSizeResource: AnyObject?
                try fileUrl.getResourceValue(&fileSizeResource, forKey: .fileSizeKey)
                guard let fileSize = fileSizeResource as? NSNumber else { continue }
                total += fileSize.uint64Value
            }
            return total
        } catch {
            Ext.debug("clac size error", error: error, tag: .file, locationEnabled: false)
        }
        return 0
    }
    
    /// 文件大小 (单位: byte)
    var fileSize: Int? {
        let keys: Set<URLResourceKey> = [.totalFileSizeKey, .fileSizeKey]
        let resourceValues = try? base.resourceValues(forKeys: keys)
//        let assetSizeBytes = tracks(withMediaType: AVMediaType.video).first?.totalSampleDataLength
        return resourceValues?.fileSize ?? resourceValues?.totalFileSize
    }
    
}
