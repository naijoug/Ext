//
//  AlbumManager.swift
//  Ext
//
//  Created by naijoug on 2022/5/10.
//

import Foundation
import Photos

/// 相册管理
public final class AlbumManager {
    public static let shared = AlbumManager()
    private init() {}
    
    private let phManager = PHCachingImageManager.default()
}

public extension AlbumManager {
    /// 媒体资源类型
    enum MediaType {
        case image
        case video
        case all
    }
    /// 媒体资源结果
    enum MediaResult {
        case image(UIImage)
        case video(URL)
        case error(Swift.Error)
    }
    
    /// 请求相册资源
    /// - Parameters:
    ///   - mediaType: 媒体资源类型
    ///   - handler: 结果
    func fetch(_ mediaType: MediaType, handler: @escaping Ext.DataHandler<PHFetchResult<PHAsset>>) {
        DispatchQueue.global(qos: .background).async {
            let options = PHFetchOptions()
            options.sortDescriptors = [
                NSSortDescriptor(key: "creationDate", ascending: false)
            ]
            let result = mediaType.fetch(options: options)
            DispatchQueue.main.async {
                handler(result)
            }
        }
    }
    
    /// 导出相册资源
    /// - Parameters:
    ///   - asset: 相册资源
    ///   - handler: 结果
    func export(_ asset: PHAsset, handler: @escaping Ext.DataHandler<MediaResult>) {
        switch asset.mediaType {
        case .image:
            requestImage(asset) { result in
                switch result {
                case .failure(let error): handler(.error(error))
                case .success(let data):
                    guard let image = UIImage(data: data) else {
                        handler(.error(Ext.Error.inner("image data error.")))
                        return
                    }
                    handler(.image(image))
                }
            }
        case .video:
            requestAVAsset(asset) { result in
                switch result {
                case .failure(let error): handler(.error(error))
                case .success(let avAsset):
                    guard let url = (avAsset as? AVURLAsset)?.url else {
                        handler(.error(Ext.Error.inner("video data error.")))
                        return
                    }
                    handler(.video(url))
                }
            }
        default:
            handler(.error(Ext.Error.inner("unknown mediaType.")))
        }
    }
}
private extension AlbumManager.MediaType {
    func fetch(options: PHFetchOptions? = nil) -> PHFetchResult<PHAsset> {
        switch self {
        case .image:    return PHAsset.fetchAssets(with: .image, options: options)
        case .video:    return PHAsset.fetchAssets(with: .video, options: options)
        case .all:      return PHAsset.fetchAssets(with: options)
        }
    }
}

public extension AlbumManager {
    
    /// 根据资源请求图片
    /// - Parameters:
    ///   - asset: 资源
    ///   - size: 图片尺寸
    ///   - queue: 回调所在队列 (默认: 主队列)
    func requestImage(_ asset: PHAsset, size: CGSize = CGSize(width: 200, height: 200), queue: DispatchQueue = .main, handler: @escaping Ext.ResultDataHandler<UIImage>) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        phManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: options) { image, userInfo in
            Ext.debug("request image | \(userInfo ?? [:])")
            queue.async {
                guard let image = image else {
                    handler(.failure(Ext.Error.inner("request image error.")))
                    return
                }
                handler(.success(image))
            }
        }
    }
    
    /// 请求图片数据
    /// - Parameters:
    ///   - asset: 相册资源
    ///   - queue: 回调所在队列 (默认: 主队列)
    ///   - handler: 图片数据
    func requestImage(_ asset: PHAsset, queue: DispatchQueue = .main, handler: @escaping Ext.ResultDataHandler<Data>) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        if #available(iOS 13, *) {
            phManager.requestImageDataAndOrientation(for: asset, options: options) { data, identifier, orientation, userInfo in
                Ext.debug("\(identifier ?? "") | \(orientation) | \(userInfo ?? [:])")
                queue.async {
                    guard let data = data else {
                        handler(.failure(Ext.Error.inner("request image data error.")))
                        return
                    }
                    handler(.success(data))
                }
            }
        } else {
            phManager.requestImageData(for: asset, options: options) { data, identifier, orientation, userInfo in
                Ext.debug("\(identifier ?? "") | \(orientation) | \(userInfo ?? [:])")
                queue.async {
                    guard let data = data else {
                        handler(.failure(Ext.Error.inner("request image data error.")))
                        return
                    }
                    handler(.success(data))
                }
            }
        }
    }
    
    
    /// 请求播放 item
    /// - Parameters:
    ///   - asset: 相册资源
    ///   - queue: 回调所在队列 (默认: 主队列)
    ///   - handler: AVPlayerItem
    func requestPlayerItem(_ asset: PHAsset, queue: DispatchQueue = .main, handler: @escaping Ext.ResultDataHandler<AVPlayerItem>) {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        phManager.requestPlayerItem(forVideo: asset, options: options) { playerItem, userInfo in
            Ext.debug("request playerItem | \(userInfo ?? [:])")
            queue.async {
                guard let playerItem = playerItem else {
                    handler(.failure(Ext.Error.inner("request playerItem error.")))
                    return
                }
                handler(.success(playerItem))
            }
        }
    }
    
    
    /// 请求 AVAsset 资源
    /// - Parameters:
    ///   - asset: 相册资源
    ///   - queue: 回调所在队列 (默认: 主队列)
    ///   - handler: AVAsset
    func requestAVAsset(_ asset: PHAsset, queue: DispatchQueue = .main, handler: @escaping Ext.ResultDataHandler<AVAsset>) {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        phManager.requestAVAsset(forVideo: asset, options: options) { avAsset, audioMix, userInfo in
            queue.async {
                Ext.debug("request avAsset | \(String(describing: avAsset)) | \(String(describing: audioMix)) | \(userInfo ?? [:])")
                queue.async {
                    guard let avAsset = avAsset else {
                        handler(.failure(Ext.Error.inner("request avAsset error.")))
                        return
                    }
                    handler(.success(avAsset))
                }
            }
        }
    }
}
