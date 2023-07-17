//
//  Popup.swift
//  Ext
//
//  Created by guojian on 2023/7/17.
//

import UIKit

/// 弹出框
public final class Popup {
    public static let shared = Popup()
    private init() {}
    
    /// 是否正在显示弹出框
    public private(set) var isPoping: Bool = false {
        didSet {
            Ext.log("Poping \(oldValue) -> \(isPoping)")
        }
    }
}

/// Popup 内容视图协议
public protocol PopupContentViewType: UIView {
    /// 内容视图用于隐藏 Popup
    var hideHandler: Ext.VoidHandler? { get set }
}

public extension Popup {
    
    struct Config {
        /// Popup 的显示容器视图 (默认最顶层 Window)
        public var containerView: UIView?
        
        /// 背景蒙层颜色
        public var backgroundColor: UIColor = .black.withAlphaComponent(0.5)
        /// 是否可以点击背景遮罩隐藏
        public var tapHiddenEnabled: Bool = true
        /// 点击背景遮罩隐藏回调
        public var tapHiddenHandler: Ext.VoidHandler?
        
        /// Popup 隐藏时回调
        public var hideHandler: Ext.VoidHandler?
        
        /// 是否在 Pop 队列中 (默认: false)
        public var inQueue: Bool = false
        
        /// 显示完成
        public var showedHandler: Ext.VoidHandler?
        /// 隐藏完成
        public var hiddenHandler: Ext.VoidHandler?
        
        public init() {}
    }
    
}

public extension Popup {
    enum Position {
        case center
        case bottom
        case fullscreen
    }
    
    func pop<T: PopupContentViewType>(_ contentView: T, position: Position, config: Config = Config()) {
        guard let view = config.containerView ?? UIWindow.ext.main else { return }
        
        let inQueue = config.inQueue && (config.containerView == nil)
        if inQueue, isPoping {
            Ext.log("正在 poping 中...")
            return
        }
        
        let popupView = PopupView()
        popupView.backgroundColor = config.backgroundColor
        popupView.tapHiddenEnabled = config.tapHiddenEnabled
        popupView.tapHideHandler = config.tapHiddenHandler
        popupView.addSubview(contentView)
        view.addSubview(popupView)
        
        popupView.ext.constraintToEdges(view)
        switch position {
        case .center:
            contentView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                contentView.leadingAnchor.constraint(equalTo: popupView.leadingAnchor),
                contentView.trailingAnchor.constraint(equalTo: popupView.trailingAnchor),
                contentView.centerYAnchor.constraint(equalTo: popupView.centerYAnchor)
            ])
        case .bottom:
            contentView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                contentView.leadingAnchor.constraint(equalTo: popupView.leadingAnchor),
                contentView.trailingAnchor.constraint(equalTo: popupView.trailingAnchor),
                contentView.bottomAnchor.constraint(equalTo: popupView.bottomAnchor)
            ])
        case .fullscreen:
            contentView.ext.constraintToEdges(popupView)
        }
        
        if inQueue {
            self.isPoping = true
        }
        
        func hide() {
            if inQueue {
                self.isPoping = false
            }
            hideAnimation(popupView) {
                popupView.removeFromSuperview()
                config.hiddenHandler?()
            }
        }
        
        popupView.hideHandler = {
            hide()
        }
        contentView.hideHandler = {
            hide()
        }
        
        // 弹出 popup 之前，暂停播放
        GlobalPlayer.shared.pause()
        // 显示 popup
        showAnimation(popupView) {
            config.showedHandler?()
        }
    }
    
    /// 显示动画效果
    private func showAnimation(_ popupView: PopupView, completion: Ext.VoidHandler? = nil) {
        popupView.alpha = 0
        UIView.animate(withDuration: .ext.animationDuration, delay: 0, options: .curveEaseIn) {
            popupView.alpha = 1
        } completion: { _ in
            completion?()
        }
    }
    /// 隐藏动画效果
    private func hideAnimation(_ popupView: PopupView, completion: Ext.VoidHandler? = nil) {
        UIView.animate(withDuration: .ext.animationDuration, delay: 0, options: .curveEaseOut) {
            popupView.alpha = 0
        } completion: { _ in
            completion?()
        }
    }
}

/// Popup 遮罩视图
private class PopupView: ExtControl, PopupContentViewType {
    var hideHandler: Ext.VoidHandler?
    
    /// 是否可以点击背景隐藏 (默认: true)
    var tapHiddenEnabled: Bool = true
    /// 点击背景回调
    var tapHideHandler: Ext.VoidHandler?
    
    open override func setupUI() {
        super.setupUI()
        addTarget(self, action: #selector(tapAction), for: .touchUpInside)
    }
    
    @objc
    private func tapAction() {
        guard tapHiddenEnabled else { return }
        tapHideHandler?()
        hideHandler?()
    }
}
