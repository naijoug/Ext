//
//  WebController.swift
//  Ext
//
//  Created by naijoug on 2020/5/27.
//

import UIKit
import WebKit

open class WebController: UIViewController {
    
    /// 是否 modal 方式显示
    public var isModal: Bool = false
    /// Web 页面 URL
    public var urlString: String?
    
// MARK: - Status
    
    /// 进度监听员
    private var progressObserver: NSKeyValueObservation?
    /// 网页加载进度
    public private(set) var progress: Double = 0 {
        didSet {
            guard oldValue != progress else { return }
            Ext.debug("web progress: \(oldValue) -> \(progress)")
        }
    }
    
    /// 开始加载时间
    private var startDate = Date()
    /// Web 加载成功时间 (秒数)
    public private(set) var loadingSeconds: TimeInterval = 0
    
    /**
     Reference:
        - https://developer.apple.com/documentation/webkit/wkusercontentcontroller
     */
    
    /**
     默认 handler 名字: native
       - 实现功能 body 中 JSON 参数
        * toWeb : 打开内嵌网页 { "method": "toWeb", "title": "xxx", "url": "http://xxx" }
        * toRoot : 回到根页面 { "method": "toRoot" }
     */
    private let defaultJSHandlerName = "native"
    public var defaultJSHandlerEnabled: Bool = true {
        didSet {
            let names = [defaultJSHandlerName]
            defaultJSHandlerEnabled ? addJSHandlerNames(names) : removeJSHandlerNames(names)
        }
    }
    
    /// JS 交互函数名列表
    public private(set) var jsHandlerNames = [String]()
    
// MARK: - UI
    
    private lazy var userContentController: WKUserContentController = { WKUserContentController() }()
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(reloadWebView), for: .valueChanged)
        return refreshControl
    }()
    
    public lazy private(set) var webView: WKWebView = {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        configuration.userContentController = userContentController
        
        let webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        view.addSubview(webView)
        webView.scrollView.alwaysBounceVertical = true
        webView.scrollView.bounces = true
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        webView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        
        return webView
    }()
    
    private lazy var indicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .gray)
        view.addSubview(indicator)
        indicator.center = view.center
        return indicator
    }()
    
    /// 是否显示中间指示器
    public var indicatorEnabled: Bool = false
    
// MARK: - Lifecycle
    
    deinit {
        removeJSHandlerNames(jsHandlerNames)
        progressObserver?.invalidate()
        progressObserver = nil
    }
    override open func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationItem.largeTitleDisplayMode = .never
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        edgesForExtendedLayout = []
        
        if isModal {
            if #available(iOS 13.0, *) {
                navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeAction))
            } else {
                navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(closeAction))
            }
        }
        
        defaultJSHandlerEnabled = true
        webView.scrollView.addSubview(refreshControl)
        progressObserver = webView.observe(\.estimatedProgress, options: [.initial, .new], changeHandler: { [weak self] _, change in
            guard let `self` = self else { return }
            self.progress = change.newValue ?? 0
        })
        
        reloadWebView()
    }
    
    /// 刷新网页
    @objc
    open func reloadWebView() {
        guard let urlString = urlString, let url = URL(string: urlString) else { return }
        Ext.debug("open url: \(url.absoluteString)")
        startDate = Date()
        webView.load(URLRequest(url: url))
        beginNetworking()
    }
    
    @objc
    private func closeAction() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - WKUIDelegate

extension WebController: WKUIDelegate {
    public func webViewDidClose(_ webView: WKWebView) {
        Ext.debug("")
    }
    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        Ext.debug(message)
    }
    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        Ext.debug(message)
    }
    public func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        Ext.debug("prompt: \(prompt) | defaultText: \(defaultText ?? "")")
    }
}

// MARK: - WKNavigationDelegate

extension WebController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        
    }
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        endNetworking()
        loadingSeconds = Date().timeIntervalSince(startDate)
        Ext.debug("webView load finish. \(loadingSeconds)")
    }
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Ext.debug("webView load fail.", error: error)
        endNetworking()
    }
    
    private func beginNetworking() {
        refreshControl.beginRefreshing()
        if indicatorEnabled { indicator.startAnimating() }
    }
    private func endNetworking() {
        if indicatorEnabled { indicator.stopAnimating() }
        refreshControl.endRefreshing()
    }
}

// MARK: - WKScriptMessageHandler

extension WebController: WKScriptMessageHandler {
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        Ext.debug("names: \(jsHandlerNames) | name: \(message.name) | body: \(message.body) | \(message.frameInfo)")
        guard jsHandlerNames.contains(message.name) else { return }
        
        jsHandler(message.name, body: message.body)
    }
    
}

// MARK: - JS Method Router

extension WebController {
    
    /// 添加 JS 交互函数名
    /// - Parameter names: 函数名列表
    public func addJSHandlerNames(_ names: [String]) {
        for name in names {
            guard !jsHandlerNames.contains(where: { $0 == name }) else { continue }
            userContentController.add(self, name: name)
            jsHandlerNames.append(name)
        }
    }
    
    /// 移除 JS 交互函数名
    /// - Parameter names: 函数名列表
    public func removeJSHandlerNames(_ names: [String]) {
        for name in names {
            guard jsHandlerNames.contains(where: { $0 == name }) else { continue }
            userContentController.removeScriptMessageHandler(forName: name)
            jsHandlerNames.removeAll(where: { $0 == name })
        }
    }
    
    /// JS 方法处理者 (子类重载实现)
    /// - Parameter name: 方法名
    /// - Parameter body: 消息体
    @objc
    open func jsHandler(_ name: String, body: Any) {
        if name == defaultJSHandlerName {
            defaultJSHandler(body)
        }
    }
    
    /// 解析 JS 发送的消息体 -> JSON
    public func parseJSON(_ body: Any) -> [String: Any]? {
        if body is String, let string = body as? String {
            var json: [String: Any]?
            do {
                json = try JSONSerialization.jsonObject(with: Data(string.utf8), options: [.allowFragments, .mutableLeaves]) as? Dictionary<String, Any>
            } catch {
                Ext.debug("JSON parse error.", error: error)
            }
            return json
        } else if body is [String: Any], let json = body as? [String: Any] {
            return json
        }
        return nil
    }
}

private extension WebController {
    
    func defaultJSHandler(_ body: Any) {
        guard let json = parseJSON(body) else { return }
        Ext.debug("\(String(describing: json))")
        guard let method = json["method"] as? String else {
            Ext.debug("method not exist.")
            return
        }
        switch method {
        case "openWeb":
            let title = json["title"] as? String
            let urlString = json["url"] as? String
            openWeb(title, urlString: urlString)
        case "toRoot":
            toRoot()
        default:
            Ext.debug("method: \(method) not implement.")
            break
        }
    }
    
    /// 打开新的网页页面
    private func openWeb(_ title: String?, urlString: String?) {
        guard let urlString = urlString else { return }
        let vc = WebController()
        vc.title = title
        vc.urlString = urlString
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    /// 回到根控制器
    private func toRoot() {
        navigationController?.popToRootViewController(animated: true)
    }
    
}
