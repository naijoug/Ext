//
//  RouteManager.swift
//  Ext
//
//  Created by naijoug on 2021/3/29.
//

import UIKit

/// 页面跳转路由管理
public final class RouteManager {
    public static let shared = RouteManager()
    private init() {}
    
    public lazy var modalWrapper: Ext.FuncHandler<UIViewController, UINavigationController> = {
        { NavigationController(rootViewController: $0) }
    }()
}

public extension RouteManager {
    
    /// 页面跳转模式
    enum Mode {
        case push
        case modal
    }
    
    /// 顶层显示控制器
    private var topController: UIViewController? { UIApplication.shared.ext.topViewController() }
    
    /// Push 进入页面
    /// - Parameter controller: 页面控制器
    /// - Parameter hidesBottomBar: 是否隐藏底部 bar
    /// - Parameter animated: 是否需要动画
    func push(_ controller: UIViewController,
              hidesBottomBar: Bool = true,
              animated: Bool = true) {
        topController?.navigationController?.pushViewController(controller, animated: animated)
    }
    
    /// Modal 进入页面
    /// - Parameter controller: 页面控制器
    /// - Parameter wrapped: 是否需要包装导航控制器
    /// - Parameter fullScreen: 是否全屏展示
    /// - Parameter animated: 是否需要动画
    func modal(_ controller: UIViewController,
               wrapped: Bool = true,
               fullScreen: Bool = false,
               animated: Bool = true) {
        let vc = wrapped ? self.modalWrapper(controller) : controller
        if fullScreen { vc.modalPresentationStyle = .fullScreen }
        topController?.present(vc, animated: animated, completion: nil)
    }
    
    
    /// 页面跳转
    /// - Parameter controller: 页面控制器
    /// - Parameter mode: 跳转模式
    /// - Parameter wrapped: modal 模式是否需要包装导航控制器
    func goto(_ controller: UIViewController, mode: Mode, wrapped: Bool) {
        switch mode {
        case .push:     push(controller)
        case .modal:    modal(controller, wrapped: wrapped)
        }
    }
}

// MARK: - System

public extension RouteManager {
    
    /// 系统打开 url
    /// - Parameter url: url
    func openURL(_ url: URL?) {
        guard let url = url else { return }
        Ext.debug("open url: \(url.absoluteString)")
        guard UIApplication.shared.canOpenURL(url) else { return }
        
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    /// 系统分享
    /// - Parameter items: 分享数据
    /// - Parameter handler: 分享完成回调
    func systemShare(_ activityItems: [Any]?, activities: [UIActivity]? = nil, handler: Ext.ResultDataHandler<String>? = nil) {
        guard let activityItems = activityItems else {
            handler?(.failure(Ext.Error.inner("share activity items is nil.")))
            return
        }
        
        let vc = UIActivityViewController(activityItems: activityItems, applicationActivities: activities)
        vc.excludedActivityTypes = [ // 剔除不需要的类型
            .message,
            .mail,
            .print,
            .copyToPasteboard,
            .assignToContact,
            .saveToCameraRoll,
            .addToReadingList,
            .openInIBooks
        ]
        vc.completionWithItemsHandler = { (type, succeed, items, error) in
            Ext.debug("\(String(describing: type)) \(succeed) \(String(describing: items)) \(String(describing: error))")
            guard succeed else {
                handler?(.failure(error ?? Ext.Error.inner("share fialure.")))
                return
            }
            handler?(.success(type?.rawValue ?? ""))
        }
        modal(vc, wrapped: false)
    }
    
    /// 进入内嵌浏览器
    /// - Parameter title: 导航栏标题
    /// - Parameter urlString: 网页 URL
    /// - Parameter mode: 跳转模式
    func toWeb(_ title: String, urlString: String, mode: Mode) {
        let vc = WebController()
        vc.title = title
        vc.urlString = urlString
        switch mode {
        case .push: push(vc)
        case .modal:
            vc.isModal = true
            modal(vc)
        }
    }
}
