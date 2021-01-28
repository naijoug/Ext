//
//  FileManager+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/28.
//

import Foundation

public extension ExtWrapper where Base == FileManager {
    
    /// remove
    func remove(_ url: URL?) {
        guard let url = url else { return }
        guard base.fileExists(atPath: url.path) else { return }
        do {
            try base.removeItem(at: url)
        } catch {
            print("remove \(url.absoluteString) failure. error : \(error.localizedDescription)")
        }
    }
    
    /// create folder is not exists.
    func createIfNotExists(_ folderUrl: URL?) {
        guard let folderUrl = folderUrl else {
            print("📂 Url is nil.")
            return
        }
        guard !base.fileExists(atPath: folderUrl.path) else {
            print("📂 is exist: \(folderUrl.path).")
            return
        }
        do {
            try base.createDirectory(at: folderUrl, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("create 📂 failed.")
        }
    }

}
