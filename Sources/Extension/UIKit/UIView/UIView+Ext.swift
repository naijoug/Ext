//
//  UIView+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/28.
//

import UIKit

// MARK: - Nib

public extension ExtWrapper where Base: UIView {
    /// 返回类型同名 identifer
    static var identifier: String {
        return "\(Base.self)"
    }
    /// 返回类型同名 Nib
    static var nib: UINib {
        return UINib(nibName: "\(identifier)", bundle: nil)
    }
    
    /// 从 nib 创建视图
    ///
    /// - Returns: 当前类型视图实例
    static func instantiateFromNib() -> Base {
        /**
         Reference:
            - https://theiconic.tech/instantiating-from-xib-using-swift-generics-632a2b3d8109
            - https://stackoverflow.com/questions/25513271/how-to-initialize-instantiate-a-custom-uiview-class-with-a-xib-file-in-swift
         */
        func instantceFromNib<T>() -> T where T: UIView {
            if let view = nib.instantiate(withOwner: nil, options: nil).first as? T {
                return view
            }
            fatalError("Load nib view failure \(self)")
        }
        return instantceFromNib()
    }
}

// MARK: - AutoLayout

public extension UILayoutPriority {
    /**
     布局优先级 (< .required)
     
     low:               250.0
     high:              750.0
     almost required:   999.0
     required:          1000.0
     */
    static var almostRequired: UILayoutPriority {
        /**
         Reference:
            - [fix AutoLayout Exception](http://aplus.rs/2017/one-solution-for-90pct-auto-layout/)
            - [CareKit - NSLayoutConstraint+Extensions](https://github.com/carekit-apple/CareKit)
         */
        return .required - 1
    }
}

public extension ExtWrapper where Base: NSLayoutConstraint {
    
    func priority(_ value: UILayoutPriority) {
        base.priority = value
    }
    
}

public extension ExtWrapper where Base: UIView  {
    
    /// 设置两个并排布局视图的优先级
    /// - Parameters:
    ///   - highView: 高优先级视图
    ///   - lowView: 低优先级视图
    static func priority(high highView: UIView, low lowView: UIView) {
        lowView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        lowView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        highView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        highView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    }
    
}

// MARK: - Frame

extension ExtWrapper where Base: UIView {
    
    public var left: CGFloat {
        get { base.frame.origin.x }
        set { base.frame.origin.x = newValue }
    }
    public var right: CGFloat {
        get { base.frame.origin.x + base.frame.size.width }
        set { base.frame.origin.x = newValue - base.frame.size.width }
    }
    public var top: CGFloat {
        get { base.frame.origin.y }
        set { base.frame.origin.y = newValue }
    }
    public var bottom: CGFloat {
        get { base.frame.origin.y + base.frame.size.height }
        set { base.frame.origin.y = newValue - base.frame.size.height }
    }
    
    public var centerX: CGFloat {
        get { base.frame.origin.x + base.frame.size.width/2 }
        set { base.frame.origin.x = newValue - base.frame.size.width/2 }
    }
    public var centerY: CGFloat {
        get { base.frame.origin.y + base.frame.size.height/2 }
        set { base.frame.origin.y = newValue - base.frame.size.height/2 }
    }
    
}

// MARK: - Visible

public extension ExtWrapper where Base: UIView {
    
    /**
     Reference:
        - https://stackoverflow.com/questions/1536923/determine-if-uiview-is-visible-to-the-user
     */
    
    /// 视图是否在屏幕可见
    func isVisible(fully: Bool = false, edgeInsets: UIEdgeInsets = .zero) -> Bool {
        guard base.superview != nil, !base.isHidden else { return false }
        guard let window = base.window, window.isKeyWindow else { return false }
        guard let rect = base.superview?.convert(base.frame, to: window) else { return false }
        
        //Ext.debug("rect: \(rect) | \(base.window?.frame ?? .zero) | \(base.superview?.frame ?? .zero)")
        guard !rect.isNull, !rect.isEmpty, !rect.size.equalTo(.zero) else { return false }
        let screenRect = UIScreen.main.bounds
        let visibleRect = CGRect(
            x: edgeInsets.left,
            y: edgeInsets.top,
            width: screenRect.width - edgeInsets.left - edgeInsets.right,
            height: screenRect.height - edgeInsets.top - edgeInsets.bottom
        )
        Ext.debug("fully: \(fully) | visibleRect: \(visibleRect) | rect: \(rect) | intersectionRect: \(rect.intersection(screenRect))")
        return fully ? visibleRect.contains(rect) : visibleRect.intersects(rect)
    }
    
}

// MARK: - Image

public extension ExtWrapper where Base: UIView {
    
    /**
    Reference:
        - https://stackoverflow.com/questions/4334233/how-to-capture-uiview-to-uiimage-without-loss-of-quality-on-retina-display
        - https://nshipster.com/image-resizing/
     */
    
    /// UIView -> UIImage
    /// - Parameters:
    ///   - opaque: 是否透明背景
    ///   - scale: 缩放比例
    func uiImage(opaque: Bool = false, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(base.bounds.size, opaque, scale)
        defer { UIGraphicsEndImageContext() }
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        base.layer.render(in: context)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
}

// MARK: - Shape

public extension ExtWrapper where Base: UIView {
    
    /// 圆角位置
    enum CornerPosition {
        case all            // 四周
        case top            // 上边
        case left           // 左边
        case right          // 右边
        case bottom         // 下边
        case topLeft        // 左上角
        case topRight       // 右上角
        case bottomLeft     // 左下角
        case bottomRight    // 右下角
        case other(corners: CACornerMask)   // 其它圆角
    }
    
    
    /// 设置视图圆角
    /// - Parameters:
    ///   - radius: 圆角半径
    ///   - position: 圆角位置
    func roundCorner(radius: CGFloat = 8, position: CornerPosition = .all) {
        // reference: https://stackoverflow.com/questions/4847163/round-two-corners-in-uiview
        
        var maskedCorners: CACornerMask = [.layerMinXMinYCorner, .layerMaxXMinYCorner,
                                           .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        switch position {
        case .top: maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        case .left: maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        case .right: maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        case .bottom: maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        case .topLeft: maskedCorners = .layerMinXMinYCorner
        case .topRight: maskedCorners = .layerMaxXMinYCorner
        case .bottomLeft: maskedCorners = .layerMinXMaxYCorner
        case .bottomRight: maskedCorners = .layerMaxXMaxYCorner
        case .other(let corners): maskedCorners = corners
        default: break
        }
        
        base.clipsToBounds = radius > 0
        base.layer.cornerRadius = radius
        base.layer.maskedCorners = maskedCorners
    }
    
    /// 边线
    func borderLine(_ width: CGFloat = 0.5, color: UIColor) {
        base.layer.borderWidth = width
        base.layer.borderColor = color.cgColor
    }
    
    /// 添加阴影
    /// - Parameters:
    ///   - color: 阴影颜色
    ///   - opacity: 透明度
    ///   - offset: 偏移量  (-1, 0): 左阴影 (1, 0): 右阴影 (0, -1): 上阴影 (0, 1): 下阴影
    ///   - radius: 半径
    ///   - spread: 伸展范围
    ///   - scale: 拉伸比例
    func dropShadow(color: UIColor = .black,
                    opacity: Float = 0.1,
                    offset: CGSize = CGSize(width: 0, height: 5),
                    radius: CGFloat = 5,
                    spread: UIEdgeInsets = .zero,
                    scale: Bool = true) {
        /**
         Reference:
            - https://stackoverflow.com/questions/39624675/add-shadow-on-uiview-using-swift-3
            - https://stackoverflow.com/questions/4754392/uiview-with-rounded-corners-and-drop-shadow
            - https://www.advancedswift.com/corners-borders-shadows
        */
        let shadowSpreadRect = CGRect(x: -spread.left,
                                      y: -spread.top,
                                      width: base.bounds.size.width + spread.left + spread.right,
                                      height: base.bounds.size.height + spread.top + spread.bottom)
        let shadowSpreadRadius =  base.layer.cornerRadius == 0 ? 0 : base.layer.cornerRadius;
        let shadowPath = UIBezierPath(roundedRect: shadowSpreadRect, cornerRadius: shadowSpreadRadius)
        
        base.layer.shadowOffset         = offset
        base.layer.shadowRadius         = radius
        base.layer.shadowOpacity        = opacity
        base.layer.shadowColor          = color.cgColor
        base.layer.shadowPath           = shadowPath.cgPath
        
        base.layer.masksToBounds        = false
        base.layer.shouldRasterize      = true
        base.layer.rasterizationScale   = scale ? UIScreen.main.scale : 1
    }
}

// MARK: - Shake

public extension ExtWrapper where Base: UIView {
    
    // Reference: https://www.hangge.com/blog/cache/detail_1603.html
    
    /// 抖动方向
    enum ShakeDirection: Int {
        case horizontal //水平抖动
        case vertical   //垂直抖动
    }
    
    /// UIView 抖动动画
    /// - Parameters:
    ///   - direction: 抖动方向 (默认: 垂直方向)
    ///   - times: 抖动次数（默认: 1次）
    ///   - interval: 每次抖动时间（默认: 0.1秒）
    ///   - delta: 抖动偏移量（默认: 1）
    ///   - recover: 动画完成是否恢复初始状态
    ///   - completion: 抖动动画结束后的回调
    func shake(direction: ShakeDirection = .vertical,
               times: Int = 1,
               interval: TimeInterval = 0.1,
               delta: CGFloat = 1,
               recover: Bool = true,
               completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: interval, animations: { () -> Void in
            switch direction {
            case .horizontal:
                self.base.layer.setAffineTransform(CGAffineTransform(translationX: delta, y: 0))
            case .vertical:
                self.base.layer.setAffineTransform(CGAffineTransform(translationX: 0, y: delta))
            }
        }) { (complete) -> Void in
            guard times == 0 else {
                self.shake(direction: direction, times: times - 1,  interval: interval, delta: delta * -1, completion: completion)
                return
            }
            guard recover else {
                completion?()
                return
            }
            UIView.animate(withDuration: interval, animations: { () -> Void in
                self.base.layer.setAffineTransform(.identity)
            }, completion: { _ in
                completion?()
            })
        }
    }
    
}

private extension UIView {
    /// do nothing for lazy view active
    func active() {}
}

public extension ExtWrapper where Base: UIView {
    
    /// do nothing for lazy view active
    func active() {
        base.active()
    }
    
    /// 添加子视图
    /// - Parameters:
    ///   - subView: 子视图
    ///   - backgroundColor: 背景颜色
    func add<T: UIView>(_ subView: T, backgroundColor: UIColor? = nil) -> T {
        base.addSubview(subView)
        if let backgroundColor = backgroundColor {
            subView.backgroundColor = backgroundColor
        }
        return subView
    }
    
    /// 添加 Label
    /// - Parameters:
    ///   - font: 字体
    ///   - color: 字体颜色
    ///   - multiline: 是否多行
    func addLabel(font: UIFont,
                  color: UIColor,
                  multiline: Bool = false) -> UILabel {
        let label = add(UILabel())
        label.font = font
        label.textColor = color
        label.numberOfLines = multiline ? 0 : 1
        return label
    }
    
    /// 添加顶部分割线
    /// - Parameter color: 线颜色
    /// - Parameter width: 线高度
    @discardableResult
    func addTopLine(color: UIColor = UIColor.ext.rgbHex(0xdddddd),
                    height: CGFloat = 0.5, edgeInsets: UIEdgeInsets = .zero) -> UIView {
        let line = add(UIView(), backgroundColor: color)
        line.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            line.heightAnchor.constraint(equalToConstant: height),
            line.topAnchor.constraint(equalTo: base.topAnchor, constant: edgeInsets.top),
            line.leadingAnchor.constraint(equalTo: base.leadingAnchor, constant: edgeInsets.left),
            line.trailingAnchor.constraint(equalTo: base.trailingAnchor, constant: edgeInsets.right)
        ])
        return line
    }
    
    /// 添加底部分割线
    /// - Parameter color: 线颜色
    /// - Parameter width: 线高度
    @discardableResult
    func addBottomLine(color: UIColor = UIColor.ext.rgbHex(0xdddddd),
                       height: CGFloat = 0.5, edgeInsets: UIEdgeInsets = .zero) -> UIView {
        let line = add(UIView(), backgroundColor: color)
        line.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            line.heightAnchor.constraint(equalToConstant: height),
            line.leadingAnchor.constraint(equalTo: base.leadingAnchor, constant: edgeInsets.left),
            line.trailingAnchor.constraint(equalTo: base.trailingAnchor, constant: edgeInsets.right),
            line.bottomAnchor.constraint(equalTo: base.bottomAnchor, constant: edgeInsets.bottom)
        ])
        return line
    }
}

// MARK: - Subtract View

/**
 Reference:
    - http://www.lymanli.com/2018/11/10/subtract-mask/
    - https://stackoverflow.com/questions/31661023/change-color-of-certain-pixels-in-a-uiimage
 */

import CoreGraphics

public extension ExtWrapper where Base: UIView {
    
    func subtrackMaskView(_ view: UIView, fillBackground: Bool = false) {
        guard let targetFrame = view.superview?.convert(view.frame, to: base) else { return }
        let backgroundColor = view.backgroundColor
        //Ext.debug("sutrack target: \(targetFrame) | backgroundColor: \(String(describing: backgroundColor))")
        
        UIGraphicsBeginImageContextWithOptions(base.bounds.size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.translateBy(x: targetFrame.origin.x, y: targetFrame.origin.y)
        if backgroundColor == nil, fillBackground {
            //Ext.debug("view is alpha & fillBackground")
            view.backgroundColor = .white
            view.layer.render(in: context)
            view.backgroundColor = nil
        } else {
            //Ext.debug("view is not alpha")
            view.layer.render(in: context)
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()?.ext.subtractMaskImage
        //Ext.debug("view backgroundColor ")
        
        let maskView = UIView()
        maskView.frame = base.bounds
        maskView.layer.contents = image?.cgImage
        
        base.mask = maskView
    }
    
}
private extension ExtWrapper where Base: UIImage {
    
    var subtractMaskImage: UIImage? {
        guard let cgImage = base.cgImage else { return nil }
        let scale: CGFloat = UIScreen.main.scale
        let pixelWidth = Int(base.size.width * scale)
        let pixelHeight = Int(base.size.height * scale)
        
        let bitmapBytesPerRow = pixelWidth
        
        //Ext.debug("draw bitmap...| scale: \(scale) | pixel: \(pixelWidth) \(pixelHeight) | pixel \(cgImage.width) \(cgImage.height) | \(bitmapBytesPerRow) ")
        guard let context = CGContext(data: nil,
                                      width: pixelWidth, height: pixelHeight,
                                      bitsPerComponent: 8, bytesPerRow: bitmapBytesPerRow,
                                      space: CGColorSpaceCreateDeviceGray(),
                                      bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue) else { return nil }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(pixelWidth), height: CGFloat(pixelHeight)))
        //Ext.debug("222")
        let startTime = Date()
        if let data = context.data {
            let pixelBuffer = data.bindMemory(to: UInt8.self, capacity: pixelHeight * bitmapBytesPerRow)
            //Ext.debug("data: \(data) | type: \(data) | pixelBuffer: \(pixelBuffer)")
            for y in 0..<pixelHeight {
                for x in 0..<bitmapBytesPerRow {
                    let val = pixelBuffer[y*bitmapBytesPerRow + x]
                    pixelBuffer[y*bitmapBytesPerRow + x] = 255 - val
                }
            }
            //Ext.debug("date end | pixelBuffer [0, 0]: \(pixelBuffer[0]) | [x: y] [\(bitmapBytesPerRow - 1), \(pixelHeight - 1)]")
        }
        Ext.debug("subtract mask image duration: \(Date().timeIntervalSince(startTime))", logEnabled: Ext.logEnabled)
        guard let maskCGImage = context.makeImage() else { return nil }
        //Ext.debug("444")
        return UIImage(cgImage: maskCGImage)
    }
}
