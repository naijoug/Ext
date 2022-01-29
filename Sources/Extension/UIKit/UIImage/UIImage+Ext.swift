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
    /// - Parameter pos: 像素点位置
    func getPixelColor(pos: CGPoint) -> UIColor? {
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
        let pixelInfo = Int(pos.y) * bytesPerRow + Int(pos.x) * 4

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
    static func color(_ color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        defer { UIGraphicsEndImageContext() }
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        return UIImage(cgImage: (image?.cgImage)!)
    }
    
    
    /// 创建文字图片
    /// - Parameters:
    ///   - title: 文字
    ///   - font: 字体大小
    ///   - color: 文字颜色
    static func title(_ title: String, font: UIFont, color: UIColor) -> UIImage {
        let nsTitle = title as NSString
        let imageH = font.lineHeight
        let imageW = nsTitle.size(withAttributes: [.font: font]).width
        
        UIGraphicsBeginImageContext(CGSize(width: imageW, height: imageH))
        defer { UIGraphicsEndImageContext() }
        nsTitle.draw(in: CGRect(x: 0, y: 0, width: imageW, height: imageH),
                     withAttributes: [
                        .font: font,
                        .foregroundColor: color
                     ])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        return UIImage(cgImage: (image?.cgImage)!)
    }
}

public extension ExtWrapper where Base: UIImage {
    
    /// 返回带透明度图片
    /// - Parameter alpha: 0.0 ~ 1.0
    func alpha(_ alpha: CGFloat) -> UIImage? {
        // Reference: https://stackoverflow.com/questions/28517866/how-to-set-the-alpha-of-an-uiimage-in-swift-programmatically
        
        return UIGraphicsImageRenderer(size: base.size, format: base.imageRendererFormat).image { _ in
            base.draw(in: CGRect(origin: .zero, size: base.size), blendMode: .normal, alpha: alpha)
        }
        
//        UIGraphicsBeginImageContextWithOptions(base.size, false, UIScreen.main.scale)
//        defer { UIGraphicsEndImageContext() }
//        base.draw(at: .zero, blendMode: .normal, alpha: alpha)
//        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// 比例缩放图片
    func scale(_ ratio: CGFloat = 1.0) -> UIImage? {
        let width = base.size.width * ratio
        let height = base.size.height * ratio
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        base.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// 压缩到指定尺寸
    func scale(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        base.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// 裁剪图片指定区域
    func clip(in frame: CGRect) -> UIImage? {
        UIGraphicsBeginImageContext(frame.size)
        defer { UIGraphicsEndImageContext() }
        base.draw(in: frame)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// 生成圆形图片
    func toCircle() -> UIImage? {
        let size = base.size
        let shotest = min(size.width, size.height)
        let outputRect = CGRect(x: 0, y: 0, width: shotest, height: shotest)
        UIGraphicsBeginImageContextWithOptions(outputRect.size, false, 0)
        defer { UIGraphicsEndImageContext() }
        let context = UIGraphicsGetCurrentContext()
        context?.addEllipse(in: outputRect)
        context?.clip()
        base.draw(in: CGRect(x: (shotest - size.width)/2,
                             y: (shotest - size.height)/2,
                             width: size.width,
                             height: size.height))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// 圆角
    func roundedCorners(_ radius: CGFloat) -> UIImage? {
        let size = base.size
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        let rect = CGRect(origin: .zero, size: size)
        UIBezierPath(roundedRect: rect, cornerRadius: radius).addClip()
        base.draw(in: rect)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
