//
//  WebController.swift
//  Ext
//
//  Created by naijoug on 2020/5/27.
//

import UIKit
import WebKit

open class WebController: UIViewController {

    public private(set) var webView: WKWebView!
    private var userContentController: WKUserContentController!
    private var refreshControl: UIRefreshControl!
    private let indicator = UIActivityIndicatorView(style: .gray)
    
    /// JS MessageHandler 交互名字 (默认: native)
    public var messageHandlerName = "native"
    /// 是否 modal 方式显示
    public var isModal: Bool = false
    /// Web 页面 URL
    public var urlString: String?
    
    /// Web 加载成功时间 (秒数)
    open var loadingSeconds: TimeInterval = 0
    
    /// 开始加载时间
    private var startDate = Date()
    
// MARK: - Lifecycle
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationItem.largeTitleDisplayMode = .never
        
        if isModal {
            if #available(iOS 13.0, *) {
                navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeAction))
            } else {
                navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(closeAction))
            }
        }
        
        setupWebView()
        
        view.addSubview(indicator)
        indicator.center = webView.center
        
        reloadWebView()
    }
    
    /// 初始化 WebView
    fileprivate func setupWebView() {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        
        userContentController = WKUserContentController()
        userContentController.add(self, name: messageHandlerName)
        
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        configuration.userContentController = userContentController
        
        webView = WKWebView(frame: CGRect.zero, configuration: configuration)
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
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(reloadWebView), for: .valueChanged)
        webView.scrollView.addSubview(refreshControl)
    }
    
    deinit {
        userContentController.removeScriptMessageHandler(forName: messageHandlerName)
    }
    
    /// 刷新网页
    @objc open func reloadWebView() {
        guard let urlString = urlString, let url = URL(string: urlString) else { return }
        Ext.debug("open url: \(url.absoluteString)")
        startDate = Date()
        webView.load(URLRequest(url: url))
        beginNetworking()
    }
    
    @objc fileprivate func closeAction() {
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
        Ext.debug("webView load fail. \(error.localizedDescription)")
        endNetworking()
    }
    
    fileprivate func beginNetworking() {
        refreshControl.beginRefreshing()
        indicator.startAnimating()
    }
    fileprivate func endNetworking() {
        indicator.stopAnimating()
        refreshControl.endRefreshing()
    }
}

// MARK: - WKScriptMessageHandler

extension WebController: WKScriptMessageHandler {
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        Ext.debug("\(message.name) | \(message.body) | \(message.frameInfo)")
        if message.name == messageHandlerName {
            parseJSMessage(message.body)
        }
    }
    
}

// MARK: - JS Method Route

extension WebController {
    
    /// 解析 JS 发送的消息体
    fileprivate func parseJSMessage(_ body: Any) {
        if body is NSString, let string = body as? String {
            var json: Dictionary<String, Any>?
            do {
                json = try JSONSerialization.jsonObject(with: Data(string.utf8), options: [.allowFragments, .mutableLeaves]) as? Dictionary<String, Any>
            } catch {
                Ext.debug("json 解析错误, \(error.localizedDescription)")
            }
            routeJSMethod(json)
        } else if body is NSDictionary, let json = body as? Dictionary<String, Any> {
            routeJSMethod(json)
        }
    }
    
    /// JS 方法路由分发
    /// - Parameter json: JS 方法数据字典
    open func routeJSMethod(_ json: Dictionary<String, Any>?) {
        Ext.debug("\(String(describing: json))")
        guard let json = json else { return }
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
    fileprivate func openWeb(_ title: String?, urlString: String?) {
        guard let urlString = urlString else { return }
        let vc = WebController()
        vc.title = title
        vc.urlString = urlString
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    /// 回到根控制器
    fileprivate func toRoot() {
        navigationController?.popToRootViewController(animated: true)
    }
    
}
