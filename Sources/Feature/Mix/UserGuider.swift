//
//  Guider.swift
//  Ext
//
//  Created by guojian on 2022/4/20.
//

import UIKit

/// 用户引导
public final class UserGuider {
    public static let shared = UserGuider()
    private init() {}
    
    public var logEnabled = false
    
    /// 当前引导的视图
    private weak var currentView: GuideView?
    
    /// 用户引导
    /// - Parameters:
    ///   - tip: 引导 tip 内容
    ///   - upImage: 向上的引导图片
    ///   - downImage: 向下的引导图片
    ///   - targetView: 目标视图 (需要镂空的定位的视图)
    ///   - hitView: 点击视图 (可点击事件穿透的视图)
    ///   - visibleEdgeInsets: 屏幕可视区域边距
    ///   - fillBackground: 是否需要填充视图
    ///   - offset: 位置偏移
    ///   - hideHandler: 点击隐藏回调
    public func guide(_ tip: NSAttributedString,
                      upImage: UIImage? = nil, downImage: UIImage? = nil,
                      targetView: UIView?, hitView: UIView? = nil,
                      visibleEdgeInsets: UIEdgeInsets = .zero,
                      fillBackground: Bool = false,
                      offset: CGPoint = CGPoint(x: 5, y: 10),
                      hideHandler: Ext.VoidHandler? = nil) {
        if let currentView = currentView {
            Ext.debug("current guide view: \(currentView)", logEnabled: logEnabled)
            currentView.removeFromSuperview()
            self.currentView = nil
        }
        
        Ext.debug("guide tip: \(tip) | target: \(String(describing: targetView)) | isVisiable: \(targetView?.ext.isVisible(fully: true, edgeInsets: visibleEdgeInsets) ?? false)", logEnabled: logEnabled)
        
        guard let targetView = targetView, targetView.frame.size != .zero, targetView.ext.isVisible(fully: true, edgeInsets: visibleEdgeInsets),
              let containerView = UIApplication.shared.ext.mainWindow else { return }
        
        let guideView = GuideView(tip, upImage: upImage, downImage: downImage)
        guideView.frame = containerView.bounds
        containerView.addSubview(guideView)
        containerView.layoutIfNeeded()
        self.currentView = guideView
        
        Ext.debug("begin.... guide view: \(guideView)", logEnabled: logEnabled)
        guideView.logEnabled = logEnabled
        guideView.hideHandler = hideHandler
        guideView.guide(targetView, hitView: hitView, fillBackground: fillBackground, offset: offset)
        Ext.debug("end.", logEnabled: logEnabled)
    }
    
}

/// 引导视图
private class GuideView: UIView {
    
    /// 点击隐藏的区域
    private var hitFrame: CGRect = .zero
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        Ext.debug("point: \(point) | frame: \(frame) | hitFrame: \(hitFrame)", logEnabled: logEnabled)
        func hide() {
            hideHandler?()
            removeFromSuperview()
        }
        guard frame.contains(hitFrame) else {
            Ext.debug("hit 区域不存，直接隐藏", logEnabled: logEnabled)
            hide()
            return nil
        }
        guard hitFrame.contains(point) else {
            return super.hitTest(point, with: event)
        }
        Ext.debug("点击 mask 区域", logEnabled: logEnabled)
        hide()
        return nil
    }
    
// MARK: - Params
    
    var logEnabled: Bool = false
    
    /// 隐藏回调
    var hideHandler: Ext.VoidHandler?
    
    var maskColor = UIColor.black.withAlphaComponent(0.7) {
        didSet {
            topView.backgroundColor = maskColor
            bottomView.backgroundColor = maskColor
            leftView.backgroundColor = maskColor
            rightView.backgroundColor = maskColor
        }
    }
    
    
// MARK: - UI
    
    /// 引导视图四周的蒙版视图
    private lazy var topView: UIView = { ext.add(UIView(), backgroundColor: maskColor) }()
    private lazy var bottomView: UIView = { ext.add(UIView(), backgroundColor: maskColor) }()
    private lazy var leftView: UIView = { ext.add(UIView(), backgroundColor: maskColor) }()
    private lazy var rightView: UIView = { ext.add(UIView(), backgroundColor: maskColor) }()
    
    private lazy var centerView: UIView = { ext.add(UIView(), backgroundColor: maskColor) }()
    
    private lazy var imageView: UIImageView = {
        ext.add(UIImageView(image: upImage)).setup {
            $0.contentMode = .center
        }
    }()
    private lazy var titleLabel: UILabel = {
        ext.add(UILabel()).setup {
            $0.numberOfLines = 0
            $0.textAlignment = .center
            $0.attributedText = attributedText
        }
    }()
    
// MARK: - Init
    
    private let attributedText: NSAttributedString
    private let upImage: UIImage?
    private let downImage: UIImage?
    init(_ attributedText: NSAttributedString, upImage: UIImage?, downImage: UIImage?) {
        self.attributedText = attributedText
        self.upImage = upImage
        self.downImage = downImage
        super.init(frame: .zero)
        
        setupUI()
    }
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    deinit {
        Ext.debug("tip: \(titleLabel.text ?? "")", tag: .recycle)
    }
    func setupUI() {
        topView.ext.active()
        bottomView.ext.active()
        leftView.ext.active()
        rightView.ext.active()
        centerView.ext.active()
    }
}

extension GuideView {
    
    func guide(_ targetView: UIView, hitView: UIView?, fillBackground: Bool = false,
               offset: CGPoint) {
        guard let targetFrame = targetView.superview?.convert(targetView.frame, to: self) else { return }
        self.hitFrame = targetFrame
        if let hitView = hitView, let frame = hitView.superview?.convert(hitView.frame, to: self) {
            self.hitFrame = frame
        }
        
        layoutMask(targetFrame)
        layoutHit(hitFrame, offset: offset)
        // 目标视图镂空处理
        centerView.ext.subtrackMaskView(targetView, fillBackground: fillBackground)
        
        shake()
    }
}

private extension GuideView {
    
    /// 遮罩区域布局
    func layoutMask(_ centerFrame: CGRect) {
        let topFrame = CGRect(x: 0,
                              y: 0,
                              width: frame.width,
                              height: max(0, centerFrame.minY))
        let bottomFrame = CGRect(x: 0,
                                 y: centerFrame.maxY,
                                 width: frame.width,
                                 height: max(0, frame.height - centerFrame.maxY))
        let leftFrame = CGRect(x: 0,
                               y: centerFrame.origin.y,
                               width: max(0, centerFrame.minX),
                               height: centerFrame.height)
        let rightFrame = CGRect(x: centerFrame.maxX,
                                y: centerFrame.origin.y,
                                width: max(0, frame.width - centerFrame.maxX),
                                height: centerFrame.height)
        Ext.debug("centerFrame: \(centerFrame)", logEnabled: logEnabled)
        Ext.debug("topFrame: \(topFrame)", logEnabled: logEnabled)
        Ext.debug("bottomFrame: \(bottomFrame)", logEnabled: logEnabled)
        Ext.debug("leftFrame: \(leftFrame)", logEnabled: logEnabled)
        Ext.debug("rightFrame: \(rightFrame)", logEnabled: logEnabled)
        topView.frame = topFrame
        bottomView.frame = bottomFrame
        leftView.frame = leftFrame
        rightView.frame = rightFrame
        centerView.frame = centerFrame
        layoutIfNeeded()
    }
    
    /// 点击区域布局
    private func layoutHit(_ hitFrame: CGRect, offset: CGPoint) {
        let hitX: CGFloat = hitFrame.origin.x + hitFrame.size.width/2
        let hitY: CGFloat = hitFrame.origin.y + hitFrame.size.height/2
        let hitH: CGFloat = hitFrame.size.height
        
        let imageH: CGFloat = imageView.frame.size.height
        
        let isTop = frame.height > (hitY + hitH/2 + imageH*2)
        Ext.debug("isTop: \(isTop) | hit: \(hitFrame) | hit center (x, y): \(hitX) \(hitY) | image \(imageView.frame) | \(frame)", logEnabled: logEnabled)
        
        imageView.image = isTop ? upImage : downImage
        let ratio = CGFloat(isTop ? 1 : -1)
        imageView.center = CGPoint(
            x: hitX + ratio * offset.x,
            y: hitY + ratio * ((imageH + hitH)/2 + offset.y)
        )
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        if isTop {
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10).isActive = true
        } else {
            titleLabel.bottomAnchor.constraint(equalTo: imageView.topAnchor, constant: -10).isActive = true
        }
        
        if hitX < frame.width/3 {
            titleLabel.textAlignment = .left
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: self.imageView.leadingAnchor),
                titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor, constant: -20)
            ])
        } else if hitX > frame.width * 2/3 {
            titleLabel.textAlignment = .right
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: self.leadingAnchor, constant: 20),
                titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: self.imageView.trailingAnchor, constant: 0)
            ])
        } else {
            titleLabel.textAlignment = .center
            NSLayoutConstraint.activate([
                titleLabel.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
                titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: self.leadingAnchor, constant: 20),
                titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor, constant: -20)
            ])
        }
    }
    
    /// shake 动画
    private func shake() {
        imageView.ext.shake(direction: .vertical, times: 3, interval: 0.3, delta: 10, recover: false) { [weak self] in
            guard let `self` = self else { return }
            //Ext.debug("继续下一次 shake", logEnabled: logEnabled)
            self.shake()
        }
    }
}
