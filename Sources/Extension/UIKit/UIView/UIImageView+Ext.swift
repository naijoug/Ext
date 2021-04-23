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
    static func animationImages(format: String, count: Int) -> [UIImage] {
        var images = [UIImage]()
        for i in 0...count {
            if let image = UIImage(named: String(format: format, i)) {
                images.append(image)
            }
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
    func animationImages(format: String, count: Int, duration: TimeInterval? = nil) {
        base.animationImages = UIImage.ext.animationImages(format: format, count: count)
        if let duration = duration {
            base.animationDuration = duration
        }
    }
    
}
