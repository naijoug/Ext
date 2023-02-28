//
//  Router.swift
//  Ext
//
//  Created by guojian on 2021/9/16.
//

import Foundation

/**
 Reference:
    - https://github.com/devxoul/URLNavigator
 */

/// 路由键值协议
public protocol RouterKey {
    /// 路由键
    var key: String { get }
}
private extension RouterKey {
    var url: String { "\(Router.shared.scheme)\(key)" }
}

/// 路由处理者键值协议
public protocol RouterHandlerKey: RouterKey {}
private extension RouterHandlerKey {
    var handlerKey: String { "handler://\(key)" }
}

/// 路由参数协议
public protocol RouterParam {
    /// 路由跳转模式
    func mode() -> Router.Mode?
}
public extension RouterParam {
    func mode() -> Router.Mode? { nil }
}

/// 可路由协议
public protocol Routable {
    /// 注册 route 功能
    static func register()
}

public extension Router {
    /// 注册可路由模块
    static func register(_ routes: [Routable.Type]) {
        routes.forEach { route in
            route.register()
        }
    }
}

/// 简单路由
public final class Router {
    public static let shared = Router()
    private init() {}
    
    /// 控制器路由表
    private var controllerMap = [String: ParamController]()
    /// 跳转模式表
    private var modeMap = [String: Router.Mode]()
    
    /// 处理者路由表
    private var handlerMap = [String: ParamHandler]()
    
    /// 路由 scheme
    public var scheme: String = "app://"
    
    /// modal 模式导航控制器包装
    public lazy var modalWrapper: Ext.FuncHandler<UIViewController, UINavigationController> = { UINavigationController(rootViewController: $0) }
}

public extension Router {
    
    typealias VoidController = () -> UIViewController?
    typealias ParamController = (_ param: RouterParam?) -> UIViewController?
    
    func register(key: RouterKey, controller: @escaping VoidController) {
        register(key: key) { _ in return controller() }
    }
    func register(key: RouterKey, mode: Mode? = nil, controller: @escaping ParamController) {
        controllerMap[key.url] = controller
        if let mode = mode {
            modeMap[key.url] = mode
        }
    }
    
    func controller(for key: RouterKey, param: RouterParam? = nil) -> UIViewController? {
        controllerMap[key.url]?(param)
    }
    func mode(for key: RouterKey) -> Mode? {
        modeMap[key.url]
    }
}

public extension Router {
    
    typealias ParamHandler = (_ param: RouterParam?) -> Void
    
    func register(key: RouterHandlerKey, handler: @escaping Ext.VoidHandler) {
        handlerMap[key.handlerKey] = { _ in handler() }
    }
    func register(key: RouterHandlerKey, handler: @escaping ParamHandler) {
        handlerMap[key.handlerKey] = handler
    }
    
    func handler(for key: RouterHandlerKey) -> ParamHandler? {
        return handlerMap[key.handlerKey]
    }
    
    func handle(key: RouterHandlerKey, param: RouterParam? = nil) {
        guard let handler = self.handler(for: key) else { return }
        handler(param)
    }
}

public extension Router {
    
    /// 顶层显示控制器
    var topController: UIViewController? { UIApplication.shared.ext.topViewController() }
    
    /// 启动页面
    func launch(key: RouterKey, param: RouterParam? = nil) {
        guard let controller = controller(for: key, param: param) else {
            Ext.inner.ext.log("❌ router: \(key.url) unregistered.")
            return
        }
        var log = "🚀 router launch \(key.url)"
        if let param = param { log += " | \(param)" }
        Ext.inner.ext.log(log)
        UIApplication.shared.ext.mainWindow?.rootViewController = controller
    }
    
    /// 页面跳转模式
    enum Mode {
        case push(hidesBottomBar: Bool = true, animated: Bool = true)
        case modal(wrapped: Bool = false, fullScreen: Bool = false, animated: Bool = true)
        
        public var isModal: Bool {
            switch self {
            case .modal: return true
            default: return false
            }
        }
    }
    
    /// 跳转到指定路由
    /// - Parameters:
    ///   - key: 路由键
    ///   - param: 路由参数
    ///   - mode: 跳转模式 (默认: Push)
    func goto(key: RouterKey, param: RouterParam? = nil, mode: Mode? = nil) {
        guard let controller = controller(for: key, param: param) else {
            Ext.inner.ext.log("❌ router: \(key.url) unregistered.")
            return
        }
        let routerMode = mode ?? param?.mode() ?? self.mode(for: key)
        var log = "✈️ router goto \(key.url) | mode \(mode.debugDescription) - \(routerMode.debugDescription)"
        if let param = param { log += " | \(param)" }
        Ext.inner.ext.log(log)
        
        goto(controller, mode: routerMode)
    }
    
    /// 跳转到指定控制器
    /// - Parameters:
    ///   - vc: 控制器
    ///   - mode: 跳转模式 (默认: Push)
    func goto(_ controller: UIViewController, mode: Mode? = nil) {
        let routerMode = mode ?? .push()
        switch routerMode {
        case .push(let hidesBottomBar, let animated):
            push(controller, hidesBottomBar: hidesBottomBar, animated: animated)
        case .modal(let wrapped, let fullScreen, let animated):
            modal(controller, wrapped: wrapped, fullScreen: fullScreen, animated: animated)
        }
    }
}

private extension Router {
    
    /// Push 进入页面
    /// - Parameter controller: 页面控制器
    /// - Parameter hidesBottomBar: 是否隐藏底部 bar
    /// - Parameter animated: 是否需要动画
    func push(_ controller: UIViewController,
              hidesBottomBar: Bool = true,
              animated: Bool = true) {
        controller.hidesBottomBarWhenPushed = hidesBottomBar
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
    func openURL(_ url: URL) {
        guard UIApplication.shared.canOpenURL(url) else {
            Ext.inner.ext.log("❌ router url can not open. | \(url.absoluteString)")
            return
        }
        Ext.inner.ext.log("☄️ router open url: \(url.absoluteString)")
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    
    /// 打开系统 alert
    /// - Parameters:
    ///   - style: alert 形式
    ///   - title: 标题
    ///   - message: 内容
    ///   - actions: 响应列表
    func alert(_ style: UIAlertController.Style, title: String?, message: String? = nil, actions: [UIAlertAction]) {
        guard !actions.isEmpty else { return }
        let controller = UIAlertController(title: title, message: message, preferredStyle: style)
        for action in actions {
            controller.addAction(action)
        }
        goto(controller, mode: .modal())
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
        vc.completionWithItemsHandler = { (type, succeeded, items, error) in
            Ext.inner.ext.log("\(String(describing: type)) \(succeeded) \(String(describing: items))", error: error)
            guard succeeded else {
                handler?(.failure(error ?? Ext.Error.inner("share fialure.")))
                return
            }
            handler?(.success(type?.rawValue ?? ""))
            vc.dismiss(animated: true, completion: nil)
        }
        return vc
    }
    
    /// 进入系统分享
    func toSystemShare(_ activityItems: [Any]?, activities: [UIActivity]? = nil, handler: Ext.ResultDataHandler<String>? = nil) {
        guard let vc = systemShare(activityItems, activities: activities, handler: handler) else { return }
        goto(vc, mode: .modal())
    }
}

public class ExtActivity: UIActivity {
    private var title: String
    private var image: UIImage?
    private var handler: Ext.VoidHandler?
    public init(title: String, image: UIImage?, handler: Ext.VoidHandler?) {
        self.title = title
        self.image = image
        self.handler = handler
        super.init()
    }
    
    public override var activityTitle: String? { title }
    public override var activityImage: UIImage? { image }
    public override class var activityCategory: UIActivity.Category { .action }
    public override func canPerform(withActivityItems activityItems: [Any]) -> Bool { true }
    public override func perform() {
        self.handler?()
        self.activityDidFinish(true)
    }
}
