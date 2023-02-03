//
//  ImageCached.swift
//  Ext
//
//  Created by naijoug on 2021/4/27.
//

import UIKit
import CoreGraphics

/// 简陋的图片缓存
public struct ImageCached {
    /// 缓存容器
    private static var cache = NSCache<AnyObject, AnyObject>()
}
public extension ImageCached {
    /// 获取缓存图片
    static func getImage(forKey key: String?) -> UIImage? {
        guard let key = key else { return  nil }
        return cache.object(forKey: key as AnyObject) as? UIImage
    }
    /// 保存缓存图片
    static func setImage(_ image: UIImage?, forKey key: String?) {
        guard let image = image, let key = key else { return }
        cache.setObject(image, forKey: key as AnyObject)
    }
    
    /// 生成图片，并且进行缓存
    /// - Parameters:
    ///   - key: 图片缓存的 Key
    ///   - processing: 加工图片函数
    ///   - handler: 图片处理成功回调
    static func makeImage(_ key: String?, processing: @escaping Ext.FuncHandler<Void, UIImage?>, handler: @escaping Ext.DataHandler<UIImage?>) {
        func callback(_ image: UIImage?) {
            DispatchQueue.main.async {
                handler(image)
            }
        }
        DispatchQueue.global().async {
            // 先去缓存中的图片
            if let image = getImage(forKey: key) {
                callback(image)
                return
            }
            // 缓存中不存在，进行图片加工
            guard let image = processing(()) else {
                callback(nil)
                return
            }
            // 缓存图片
            setImage(image, forKey: key)
            callback(image)
        }
    }
}
