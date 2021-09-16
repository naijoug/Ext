//
//  Router.swift
//  Ext
//
//  Created by guojian on 2021/9/16.
//

import Foundation

/// 路由键值协议
public protocol RouterKey {
    /// 路由键
    var key: String { get }
}
private extension RouterKey {
    var url: String { "\(Router.shared.scheme)\(key)" }
}

/// 路由参数协议
public protocol RouterParam {}

/// 简单路由
public final class Router {
    public static let shared = Router()
    private init() {}
    
    /// 路由表
    private var routerMap = [String: ParamController]()
    
    /// 路由 scheme
    public var scheme: String = "app://"
    
    /// modal 模式导航控制器包装
    public lazy var modalWrapper: Ext.FuncHandler<UIViewController, UINavigationController> = {
        { NavigationController(rootViewController: $0) }
    }()
}

public extension Router {
    
    typealias VoidController = () -> UIViewController?
    typealias ParamController = (_ param: RouterParam?) -> UIViewController?
    
    func register(key: RouterKey, controller: @escaping VoidController) {
        register(key: key) { _ in return controller() }
    }
    
    func register(key: RouterKey, controller: @escaping ParamController) {
        routerMap[key.url] = controller
    }
    
    func controller(for key: RouterKey, param: RouterParam? = nil) -> UIViewController? {
        return routerMap[key.url]?(param)
    }
}

public extension Router {
    
    static weak var window: UIWindow?
    
    func launch(key: RouterKey, param: RouterParam? = nil) {
        guard let controller = controller(for: key, param: param) else { return }
        Router.window?.rootViewController = controller
    }
    
    /// 页面跳转模式
    enum Mode {
        case push
        case modal
    }
    
    /// 跳转到指定路由
    /// - Parameters:
    ///   - key: 路由键
    ///   - param: 路由参数
    ///   - mode: 跳转模式
    func goto(key: RouterKey, param: RouterParam? = nil, mode: Mode = .push) {
        guard let controller = controller(for: key, param: param) else { return }
        var log = "route to \(key.url)"
        if let param = param { log += " | \(param)" }
        Ext.debug(log, tag: .custom("🐉✈️☄️"), locationEnabled: false)
        
        goto(controller, mode: mode)
    }
    
    /// 跳转到指定控制器
    /// - Parameters:
    ///   - vc: 控制器
    ///   - mode: 跳转模式
    func goto(_ controller: UIViewController, mode: Mode = .push) {
        switch mode {
        case .push:
            push(controller)
        case .modal:
            modal(controller)
        }
    }
}

private extension Router {
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
               wrapped: Bool = false,
               fullScreen: Bool = false,
               animated: Bool = true) {
        let vc = wrapped ? self.modalWrapper(controller) : controller
        if fullScreen { vc.modalPresentationStyle = .fullScreen }
        topController?.present(vc, animated: animated, completion: nil)
    }
}

public extension Router {
    
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
    func systemShare(_ activityItems: [Any]?, activities: [UIActivity]? = nil, handler: Ext.ResultDataHandler<String>? = nil) -> UIActivityViewController? {
        guard let activityItems = activityItems else {
            handler?(.failure(Ext.Error.inner("share activity items is nil.")))
            return nil
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
            vc.dismiss(animated: true, completion: nil)
        }
        return vc
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
        case .push:
            push(vc)
        case .modal:
            vc.isModal = true
            modal(vc)
        }
    }
}
