//
//  UIImageView+Ext.swift
//  Ext
//
//  Created by guojian on 2020/12/28.
//

import UIKit

public extension ExtWrapper where Base == UIImage {
    /// 创建帧动图
    /// - Parameters:
    ///   - format: "icon_xx_%04d_"
    ///   - count: 帧图片数量
    static func animationImages(format: String, count: Int, bundle: Bundle? = nil) -> [UIImage] {
        var images = [UIImage]()
        for i in 0...count {
            guard let image = (bundle ?? .main).ext.image(String(format: format, i)) else { continue }
            images.append(image)
        }
        return images
    }
}
public extension ExtWrapper where Base: UIImageView {

    
    /// 设置帧动画图片
    /// - Parameters:
    ///   - format: 帧图片格式 "icon_xx_%04d"
    ///   - count: 帧图片数量
    ///   - duration: 帧动画持续时间
    func animationImages(format: String, count: Int, duration: TimeInterval? = nil, bundle: Bundle? = nil) {
        base.animationImages = UIImage.ext.animationImages(format: format, count: count, bundle: bundle)
        if let duration = duration {
            base.animationDuration = duration
        }
    }
    
}
