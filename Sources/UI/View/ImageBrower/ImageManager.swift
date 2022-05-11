//
//  ImageManager.swift
//  Ext
//
//  Created by naijoug on 2022/5/10.
//

import Foundation
import Photos

/// 图片管理
public final class ImageManager {
    public static let shared = ImageManager()
    private init() {}
    
    private let phManager = PHCachingImageManager.default()
}

public extension ImageManager {
    func requestImage(_ asset: PHAsset, handler: @escaping Ext.ResultDataHandler<Data>) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        if #available(iOS 13, *) {
            phManager.requestImageDataAndOrientation(for: asset, options: options) { data, identifier, orientation, userInfo in
                Ext.debug("\(identifier ?? "") | \(orientation) | \(userInfo ?? [:])")
                guard let data = data else {
                    handler(.failure(Ext.Error.inner("request image data error.")))
                    return
                }
                handler(.success(data))
            }
        } else {
            phManager.requestImageData(for: asset, options: options) { data, identifier, orientation, userInfo in
                Ext.debug("\(identifier ?? "") | \(orientation) | \(userInfo ?? [:])")
                guard let data = data else {
                    handler(.failure(Ext.Error.inner("request image data error.")))
                    return
                }
                handler(.success(data))
            }
        }
    }
}
