//
//  WebController.swift
//  Ext
//
//  Created by naijoug on 2020/5/27.
//

import UIKit
import WebKit

/**
 Reference:
    - https://developer.apple.com/documentation/webkit/wkusercontentcontroller
    - https://stackoverflow.com/questions/27105094/how-to-remove-cache-in-wkwebview
    - https://stackoverflow.com/questions/34185339/wkwebview-javascript-confirm-and-alert-not-working
 */

public extension ExtWrapper where Base: WKWebView {
    
    /// 清理 WKWebView 缓存数据
    /// - Parameter handler: 清理完成回调
    static func clean(_ handler: @escaping Ext.VoidHandler) {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        WKWebsiteDataStore.default().removeData(
            ofTypes: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache],
            modifiedSince: Date(timeIntervalSince1970: 0)) {
                handler()
            }
    }
    
}

open class WebController: UIViewController {
    
    private let resource: WebResource
    
    public init(_ resource: WebResource) {
        self.resource = resource
        super.init(nibName: nil, bundle: nil)
    }
    @available(*, unavailable)
    required public init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    /// 是否 modal 方式显示
    public var isModal: Bool = false
    
// MARK: - UI
    
    public private(set) lazy var webView: WebView = {
        let webView = view.ext.add(WebView())
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        return webView
    }()
    
// MARK: - Lifecycle
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        edgesForExtendedLayout = []
        
        navigationItem.largeTitleDisplayMode = .never
        if isModal {
            if #available(iOS 13.0, *) {
                navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeAction))
            } else {
                navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(closeAction))
            }
        }
        
        webView.load(resource)
    }
    
    @objc
    private func closeAction() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - WebView

/// 网页资源
public enum WebResource {
    /// 网页地址
    case url(_ urlString: String, header: [String: String]? = nil)
    /// 网页 html 代码
    case html(_ htmlString: String)
    /// 网页文件
    case file(_ filePath: String)
}

/// 网页视图
open class WebView: ExtView, ExtInnerLogable {
    public var logLevel: Ext.LogLevel = .default
    
    /// 加载的网络资源
    public private(set) var resource: WebResource?
    
    /// 开始加载时间
    private var startDate = Date()
    /// Web 加载成功时间 (秒数)
    public private(set) var loadingSeconds: TimeInterval = 0
    /// 进度监听员
    private var progressObserver: NSKeyValueObservation?
    /// 网页加载进度
    public private(set) var progress: Double = 0 {
        didSet {
            guard Int(oldValue * 10) != Int(progress * 10) else { return }
            ext.log("web progress: \(oldValue) -> \(progress)")
        }
    }
    
// MARK: - JS Handler
    
    /// JS 交互处理者
    public typealias JSHandler = (String, Any) -> Void
    /// JS 交互处理表
    private var jsHandlers = [String: JSHandler]()
    
    /**
     默认 JS 交换功能是否可用
        handler 名字: "native"
        - 实现功能 body 中 JSON 参数
            * toWeb : 打开内嵌网页 { "method": "toWeb", "title": "xxx", "url": "http://xxx" }
            * toRoot : 回到根页面 { "method": "toRoot" }
     */
    public var defaultJSHandlerEnabled: Bool = false {
        didSet {
            defaultJSHandler(defaultJSHandlerEnabled)
        }
    }
    
// MARK: - Status
    
    /// 下拉刷新是否可用
    public var pullToRefreshEnabled: Bool = false {
        didSet {
            guard pullToRefreshEnabled else {
                refreshControl.removeFromSuperview()
                return
            }
            webView.scrollView.addSubview(refreshControl)
        }
    }
    /// 是否显示中间指示器
    public var indicatorEnabled: Bool = false
    /// 网页是否可以滚动
    public var isScrollEnabled: Bool = true {
        didSet {
            webView.scrollView.isScrollEnabled = isScrollEnabled
        }
    }
    
// MARK: - UI
    
    private lazy var userContentController = WKUserContentController()
    
    private lazy var webView: WKWebView = {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        configuration.userContentController = userContentController
        configuration.allowsInlineMediaPlayback = true
        
        let webView = ext.add(WKWebView(frame: CGRect.zero, configuration: configuration))
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.scrollView.bounces = true
        webView.scrollView.alwaysBounceVertical = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: self.topAnchor),
            webView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        
        return webView
    }()
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(pullDownToRefresh), for: .valueChanged)
        return refreshControl
    }()
    
    private lazy var indicator: UIActivityIndicatorView = {
        let indicator = ext.add(UIActivityIndicatorView(style: .gray))
        indicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
        return indicator
    }()
    
    private var topController: UIViewController? { UIApplication.ext.topViewController() }
    
// MARK: -
    
    deinit {
        for name in jsHandlers.keys {
            removeJSHandler(name)
        }
    }
    
    open override func setupUI() {
        super.setupUI()
        
        progressObserver = webView.observe(\.estimatedProgress, options: [.initial, .new], changeHandler: { [weak self] _, change in
            guard let self else { return }
            self.ext.log("estimatedProgress : \(change.oldValue ?? 0) -> \(change.newValue ?? 0)")
            self.progress = change.newValue ?? 0
        })
    }
    
    /// 下拉刷新
    @objc
    private func pullDownToRefresh() {
        guard let resource = resource, load(resource) else {
            endNetworking()
            return
        }
    }
}

// MARK: - Public

public extension WebView {
    
    /**
     设置 userAgent
     */
    func setUserAgent(_ userAgent: String) {
        webView.customUserAgent = userAgent
    }
    
    /// 添加 JS 交互函数
    /// - Parameters:
    ///   - name: JS 交互函数名
    ///   - handler: 交互函数处理者
    func addJSHandler(_ name: String, handler: @escaping JSHandler) {
        removeJSHandler(name)
        
        userContentController.add(self, name: name)
        jsHandlers[name] = handler
    }
    /// 移除 JS 交互函数名
    /// - Parameter names: JS 交互函数名
    func removeJSHandler(_ name: String) {
        guard jsHandlers.keys.contains(name) else { return }
        userContentController.removeScriptMessageHandler(forName: name)
        jsHandlers.removeValue(forKey: name)
    }
    
    /// 加载网页资源
    @discardableResult
    func load(_ resource: WebResource) -> Bool {
        switch resource {
        case .url(let urlString, let header):
            guard let url = URL(string: urlString) else { return false }
            var request = URLRequest(url: url)
            for (key, value) in header ?? [:] {
                request.setValue(value, forHTTPHeaderField: key)
            }
            ext.log("open url: \(url.absoluteString) | header: \(request.allHTTPHeaderFields ?? [:])")
            webView.load(request)
        case .html(let htmlString):
            ext.log("open html: \(htmlString)")
            webView.loadHTMLString(htmlString, baseURL: nil)
        case .file(let filePath):
            ext.log("open file: \(filePath)")
            let fileURL = URL(fileURLWithPath: filePath)
            webView.loadFileURL(fileURL, allowingReadAccessTo: fileURL.deletingLastPathComponent())
        }
        
        startDate = Date()
        beginNetworking()
        
        self.resource = resource
        
        return true
    }
    
    /// 刷新网页
    func refresh() {
        guard let resource = resource else { return }
        load(resource)
    }
    
    /// 设置 web 页面背景颜色
    func setBackgroundColor(_ backgroundColor: UIColor) {
        // solution: https://developer.apple.com/forums/thread/121139
        
        webView.isOpaque = false
        webView.backgroundColor = backgroundColor
    }
}

// MARK: - WKUIDelegate

extension WebView: WKUIDelegate {
    open func webViewDidClose(_ webView: WKWebView) {
        ext.log("")
    }
    open func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        ext.log(message)
        //completionHandler()
        guard let topController = topController else {
            completionHandler()
            return
        }
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
            completionHandler()
        }))
        topController.present(alert, animated: true)
        
    }
    open func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        ext.log(message)
        //completionHandler(false)
        guard let topController = topController else {
            completionHandler(false)
            return
        }
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
            completionHandler(true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { _ in
            completionHandler(false)
        }))
        topController.present(alert, animated: true)
    }
    open func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        ext.log("prompt: \(prompt) | defaultText: \(defaultText ?? "")")
        //completionHandler(nil)
        guard let topController = topController else {
            completionHandler(nil)
            return
        }
        let alert = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = defaultText
        }
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
            guard let text = alert.textFields?.first?.text else {
                completionHandler(defaultText)
                return
            }
            completionHandler(text)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { _ in
            completionHandler(nil)
        }))
        topController.present(alert, animated: true)
    }
}

// MARK: - WKNavigationDelegate

extension WebView: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        
    }
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        endNetworking()
        loadingSeconds = Date().timeIntervalSince(startDate)
        ext.log("webView load succeeded. \(loadingSeconds)")
    }
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        ext.log("webView load failed.", error: error)
        endNetworking()
    }
    
    private func beginNetworking() {
        if indicatorEnabled { indicator.startAnimating() }
    }
    private func endNetworking() {
        if indicatorEnabled { indicator.stopAnimating() }
        if pullToRefreshEnabled { refreshControl.endRefreshing() }
    }
}

// MARK: - WKScriptMessageHandler

extension WebView: WKScriptMessageHandler {
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        ext.log("names: \(jsHandlers.keys) | name: \(message.name) | body: \(message.body) | \(message.frameInfo)")
        guard let handler = jsHandlers[message.name] else { return }
        handler(message.name, message.body)
    }
    
}

private extension WebView {
    
    func defaultJSHandler(_ enabled: Bool) {
        let defaultJSHandlerName = "native"
        
        guard enabled else {
            removeJSHandler(defaultJSHandlerName)
            return
        }
        addJSHandler(defaultJSHandlerName) { [weak self] name, body in
            guard let self, let dict = self.prase(body) else { return }
            self.ext.log("\(dict)")
            guard let method = dict["method"] as? String else {
                self.ext.log("method not exist.")
                return
            }
            switch method {
            case "openWeb": // 打开新的网页页面
                let title = dict["title"] as? String
                guard let urlString = dict["url"] as? String else { return }
                let web = WebController(.url(urlString))
                web.title = title
                self.topController?.navigationController?.pushViewController(web, animated: true)
            case "toRoot": // 回到根控制器
                self.topController?.navigationController?.popToRootViewController(animated: true)
            default:
                self.ext.log("method: \(method) not implement.")
            }
        }
    }
    
    private func prase(_ body: Any) -> [String: Any]? {
        if body is String, let string = body as? String {
            do {
                let data = Data(string.utf8)
                let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments, .mutableLeaves])
                return json as? [String: Any]
            } catch {
                ext.log("parse web js body to dict failed.", error: error)
            }
        } else if body is [String: Any], let json = body as? [String: Any] {
            return json
        }
        return nil
    }
}
