//
//  UIImage+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/28.
//

import UIKit
import CoreImage

public extension ExtWrapper where Base == UIImage {
    
    /// 没有系统渲染的原始图片
    var original: UIImage { return base.withRenderingMode(.alwaysOriginal) }
    
    /** Reference:
        - https://stackoverflow.com/questions/25146557/how-do-i-get-the-color-of-a-pixel-in-a-uiimage-with-swift
        - https://stackoverflow.com/questions/34593706/why-do-i-get-the-wrong-color-of-a-pixel-with-following-code
     */
    
    /// 获取图片像素点颜色
    /// - Parameter point: 像素点位置
    func pixelColor(at point: CGPoint) -> UIColor? {
        guard let cgImage = base.cgImage,
            let pixelData = cgImage.dataProvider?.data
            else { return nil }

        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)

        let alphaInfo = cgImage.alphaInfo
        assert(alphaInfo == .premultipliedFirst || alphaInfo == .first || alphaInfo == .noneSkipFirst, "This routine expects alpha to be first component")

        if #available(iOS 12.0, *) {
            let byteOrderInfo = cgImage.byteOrderInfo
            assert(byteOrderInfo == .order32Little || byteOrderInfo == .orderDefault, "This routine expects little-endian 32bit format")
        }

        let bytesPerRow = cgImage.bytesPerRow
        let pixelInfo = Int(point.y) * bytesPerRow + Int(point.x) * 4

        let a: CGFloat = CGFloat(data[pixelInfo+3]) / 255
        let r: CGFloat = CGFloat(data[pixelInfo+2]) / 255
        let g: CGFloat = CGFloat(data[pixelInfo+1]) / 255
        let b: CGFloat = CGFloat(data[pixelInfo  ]) / 255

        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
    
    /// 创建纯色图片
    /// - Parameters:
    ///   - color: 颜色
    ///   - size: 图片尺寸 (默认: 1x1)
    static func color(_ color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage? {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContext(rect.size)
        defer { UIGraphicsEndImageContext() }
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    
    /// 创建文字图片
    /// - Parameters:
    ///   - title: 文字
    ///   - font: 字体大小
    ///   - color: 文字颜色
    static func title(_ title: String, font: UIFont, color: UIColor) -> UIImage? {
        let size = (title as NSString).size(withAttributes: [.font: font])
        return UIGraphicsImageRenderer(size: size).image { _ in
            (title as NSString).draw(
                in: CGRect(origin: .zero, size: size),
                withAttributes: [
                    .font: font,
                    .foregroundColor: color
                ])
        }
    }
    
    /// 创建文字图片
    /// - Parameters:
    ///   - title: 文字
    ///   - font: 字体大小
    ///   - color: 文字颜色
    static func titleColor(_ title: String, bgColor: UIColor, font: UIFont, color: UIColor) -> UIImage? {
        let size = (title as NSString).size(withAttributes: [.font: font])
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContext(rect.size)
        defer { UIGraphicsEndImageContext() }
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        (title as NSString).draw(
            in: CGRect(origin: .zero, size: size),
            withAttributes: [
                .font: font,
                .foregroundColor: color
            ])
        return UIGraphicsGetImageFromCurrentImageContext()
        
//        return UIGraphicsImageRenderer(size: size).image { context in
//            (title as NSString).draw(
//                in: CGRect(origin: .zero, size: size),
//                withAttributes: [
//                    .font: font,
//                    .foregroundColor: color
//                ])
//        }
    }
}

public extension ExtWrapper where Base: UIImage {
    
    /**
     Reference:
        - https://stackoverflow.com/questions/28517866/how-to-set-the-alpha-of-an-uiimage-in-swift-programmatically
        - https://stackoverflow.com/questions/34984966/rounding-uiimage-and-adding-a-border
     */
    
    /// 返回带透明度图片
    /// - Parameter alpha: 0.0 ~ 1.0
    func alpha(_ alpha: CGFloat) -> UIImage? {
        UIGraphicsImageRenderer(size: base.size, format: base.imageRendererFormat).image { _ in
            base.draw(in: CGRect(origin: .zero, size: base.size), blendMode: .normal, alpha: alpha)
        }
    }
    
    /// 缩放模式
    enum ScaleMode {
        /// 按尺寸缩放
        case size(_ size: CGSize)
        /// 按比例缩放
        case ratio(_ ratio: CGFloat)
    }
    
    /// 缩放
    /// - Parameter mode: 缩放模式
    func scale(in mode: ScaleMode) -> UIImage? {
        switch mode {
        case .size(let size):
            return UIGraphicsImageRenderer(size: size, format: base.imageRendererFormat).image { _ in
                base.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            }
        case .ratio(let ratio):
            return scale(in: .size(CGSize(width: base.size.width * ratio, height: base.size.height * ratio)))
        }
    }
    
    /// 裁剪图片指定区域
    func clip(in frame: CGRect) -> UIImage? {
        UIGraphicsImageRenderer(size: frame.size, format: base.imageRendererFormat).image { _ in
            base.draw(in: frame)
        }
    }
    
    /// 竖向图片
    var isPortrait:  Bool { base.size.height > base.size.width }
    /// 横向图片
    var isLandscape: Bool { base.size.width > base.size.height }
    
    /// 图片添加圆形边框
    /// - Parameters:
    ///   - width: 线框宽度
    ///   - color: 线框颜色
    func borderRounded(_ width: CGFloat, color: UIColor) -> UIImage? {
        let short = min(base.size.width, base.size.height)
        let outRect = CGRect(origin: .zero, size: CGSize(width: short, height: short))
        return UIGraphicsImageRenderer(size: outRect.size, format: base.imageRendererFormat).image { context in
            UIBezierPath(ovalIn: outRect).addClip()
            base.draw(in: outRect)
            context.cgContext.setStrokeColor(color.cgColor)
            let line = UIBezierPath(ovalIn: outRect)
            line.lineWidth = width
            line.stroke()
        }
    }
    
    /// 裁剪为圆形图片
    var circle: UIImage? {
        let short = min(base.size.width, base.size.height)
        let outputRect = CGRect(origin: .zero, size: CGSize(width: short, height: short))
        UIGraphicsBeginImageContextWithOptions(outputRect.size, false, 0)
        defer { UIGraphicsEndImageContext() }
        let context = UIGraphicsGetCurrentContext()
        context?.addEllipse(in: outputRect)
        context?.clip()
        base.draw(in: CGRect(x: (short - base.size.width)/2,
                             y: (short - base.size.height)/2,
                             width: base.size.width,
                             height: base.size.height))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// 圆角
    func roundedCorners(_ radius: CGFloat) -> UIImage? {
        let size = base.size
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        let rect = CGRect(origin: .zero, size: size)
        UIBezierPath(roundedRect: rect, cornerRadius: radius).addClip()
        base.draw(in: rect)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
