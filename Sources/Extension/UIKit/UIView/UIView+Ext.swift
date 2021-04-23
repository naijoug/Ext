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

// MARK: - Frame

extension ExtWrapper where Base: UIView {
    
    public var left: CGFloat {
        get { return base.frame.origin.x }
        set { base.frame.origin.x = newValue }
    }
    public var right: CGFloat {
        get { return base.frame.origin.x + base.frame.size.width }
        set { base.frame.origin.x = newValue - base.frame.size.width }
    }
    public var top: CGFloat {
        get { return base.frame.origin.y }
        set { base.frame.origin.y = newValue }
    }
    public var bottom: CGFloat {
        get { return base.frame.origin.y + base.frame.size.height }
        set { base.frame.origin.y = newValue - base.frame.size.height }
    }
    
    public var centerX: CGFloat {
        get { return base.frame.origin.x + base.frame.size.width/2 }
        set { base.frame.origin.x = newValue - base.frame.size.width/2 }
    }
    public var centerY: CGFloat {
        get { return base.frame.origin.y + base.frame.size.height/2 }
        set { base.frame.origin.y = newValue - base.frame.size.height/2 }
    }
    
}

// MARK: - Image

public extension ExtWrapper where Base: UIView {
    
    // Reference: https://stackoverflow.com/questions/4334233/how-to-capture-uiview-to-uiimage-without-loss-of-quality-on-retina-display
    
    /// UIView -> UIImage
    /// - Parameters:
    ///   - opaque: 是否透明背景
    ///   - scale: 缩放比例
    func uiImage(opaque: Bool = false, scale: CGFloat = 1) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(base.bounds.size, opaque, scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }
        base.layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
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
        
        base.clipsToBounds = true
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
        // Reference: https://stackoverflow.com/questions/39624675/add-shadow-on-uiview-using-swift-3
        
        let shadowSpreadRect = CGRect(x: -spread.left,
                                      y: -spread.top,
                                      width: base.bounds.size.width + spread.left + spread.right,
                                      height: base.bounds.size.height + spread.top + spread.bottom)
        let shadowSpreadRadius =  base.layer.cornerRadius == 0 ? 0 : base.layer.cornerRadius;
        let shadowPath = UIBezierPath(roundedRect: shadowSpreadRect, cornerRadius: shadowSpreadRadius)
        
        base.layer.shadowOffset = offset
        base.layer.shadowRadius = radius
        base.layer.shadowOpacity = opacity
        base.layer.shadowColor = color.cgColor
        base.layer.shadowPath = shadowPath.cgPath
        base.layer.masksToBounds = false
        base.layer.shouldRasterize = true
        base.layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }
}

// MARK: - Shake

extension ExtWrapper where Base: UIView {
    
    // Reference: https://www.hangge.com/blog/cache/detail_1603.html
    
    /// 抖动方向
    public enum ShakeDirection: Int {
        case horizontal //水平抖动
        case vertical   //垂直抖动
    }
    
    /// UIView 抖动动画
    /// - Parameters:
    ///   - direction: 抖动方向 (默认: 垂直方向)
    ///   - times: 抖动次数（默认: 1次）
    ///   - interval: 每次抖动时间（默认: 0.1秒）
    ///   - delta: 抖动偏移量（默认: 1）
    ///   - completion: 抖动动画结束后的回调
    public func shake(direction: ShakeDirection = .vertical,
                      times: Int = 1,
                      interval: TimeInterval = 0.1,
                      delta: CGFloat = 1,
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
            UIView.animate(withDuration: interval, animations: { () -> Void in
                self.base.layer.setAffineTransform(CGAffineTransform.identity)
            }, completion: { (complete) -> Void in
                completion?()
            })
        }
    }
    
}

public extension ExtWrapper where Base: UIView {
    
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
    ///   - fontSize: 字体大小
    ///   - color: 字体颜色
    ///   - hasBold: 是否加粗
    ///   - multiline: 是否多行
    func addLabel(fontSize: CGFloat,
                  color: UIColor,
                  hasBold: Bool = false,
                  multiline: Bool = false) -> UILabel {
        let label = add(UILabel())
        label.textColor = color
        label.numberOfLines = multiline ? 0 : 1
        label.font = hasBold ? UIFont.boldSystemFont(ofSize: fontSize) : UIFont.systemFont(ofSize: fontSize)
        return label
    }
    
    /// 添加顶部分割线
    /// - Parameter color: 分割线颜色
    /// - Parameter border: 分割线宽度
    @discardableResult func addTopLine(color: UIColor = UIColor.ext.rgbHex(0xdddddd),
                                              border: CGFloat = 0.5,
                                              left: CGFloat = 0,
                                              right: CGFloat = 0) -> UIView {
        let line = add(UIView(), backgroundColor: color)
        line.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            line.topAnchor.constraint(equalTo: base.topAnchor),
            line.leftAnchor.constraint(equalTo: base.leftAnchor, constant: left),
            line.rightAnchor.constraint(equalTo: base.rightAnchor, constant: right),
            line.heightAnchor.constraint(equalToConstant: border)
        ])
        return line
    }
    
    /// 添加底部分割线
    /// - Parameter color: 分割线颜色
    /// - Parameter border: 分割线宽度
    @discardableResult func addBottomLine(color: UIColor = UIColor.ext.rgbHex(0xdddddd),
                                                 border: CGFloat = 0.5,
                                                 left: CGFloat = 0,
                                                 right: CGFloat = 0) -> UIView {
        let line = add(UIView(), backgroundColor: color)
        line.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            line.bottomAnchor.constraint(equalTo: base.bottomAnchor),
            line.leftAnchor.constraint(equalTo: base.leftAnchor, constant: left),
            line.rightAnchor.constraint(equalTo: base.rightAnchor, constant: right),
            line.heightAnchor.constraint(equalToConstant: border)
        ])
        return line
    }
}
