//
//  Networker.swift
//  Ext
//
//  Created by naijoug on 2021/3/10.
//

import Foundation

/**
 HTTP 请求方法
 Reference:
    - https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Methods
 */
public enum HttpMethod: String {
    case get        = "GET"
    case head       = "HEAD"
    case post       = "POST"
    case put        = "PUT"
    case delete     = "DELETE"
    case connect    = "CONNECT"
    case options    = "OPTIONS"
    case trace      = "TRACE"
    case patch      = "PATCH"
}

/// 进度回调
public typealias ProgressHandler = (_ progress: Double, _ speed: Double) -> Void

/// Networker
public final class Networker: NSObject, ExtLogable {
    /// 是否打印日志
    public var logEnabled: Bool = true
    /// 是否打印 HTTP headers 日志
    public var headerLogged: Bool = false
    /// 是否打印下载日志
    public var downloadLogged: Bool = false
    
    public static let shared = Networker()
    private override init() {
        super.init()
    }
    
    /// 数据请求 Session
    private(set) lazy var dataSession: URLSession = {
        URLSession(configuration: URLSessionConfiguration.default)
    }()
    
    /// 下载 Session
    private(set) lazy var downloadSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "DownloadSession")
        let session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
        return session
    }()
    /// 下载队列
    private let downloadQueue = DispatchQueue(label: "ext.download.queue", qos: .utility)
    /// 下载任务列表
    private var downloadTasks = [String: [DownloadTask]]()
}

public extension Networker {
    /// 网络错误
    enum Error: Swift.Error {
        /// 无效的 URL
        case invalidURL
        /// 无响应数据
        case noResponseData
        /// 非 HTTP 响应体
        case nonHTTPResponse(response: URLResponse)
        /// HTTP 响应失败 (statusCode != 200...299)
        case httpResponseFailed(response: HTTPURLResponse, data: Data?)
    }
}
extension Networker.Error: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "invalid url"
        case .noResponseData:
            return "no response data"
        case .nonHTTPResponse(_):
            return "not http response"
        case .httpResponseFailed(let response, _):
            return "http response failed. \(response.statusCode)"
        }
    }
}

extension Networker {
    
    /// 添加一个下载任务
    func append(_ task: DownloadTask) -> Bool {
        let key = task.url.absoluteString
        var tasks = downloadTasks[key] ?? [DownloadTask]()
        if !tasks.isEmpty, tasks.contains(where: { $0.stamp == task.stamp }) {
            ext.log("已经包含该 \(task.stamp) 任务", logEnabled: downloadLogged, locationEnabled: false)
            return false
        }
        tasks.append(task)
        downloadTasks[key] = tasks
        ext.log("添加下载任务: \(task.stamp) | \(task.startTime) | \(key)", logEnabled: downloadLogged, locationEnabled: false)
        return true
    }
    /// 查询下载任务
    func tasks(for url: URL?) -> [DownloadTask]? {
        guard let key = url?.absoluteString else { return nil }
        return downloadTasks[key]
    }
    /// 删除下载任务
    func remove(for url: URL?) -> [DownloadTask]? {
        guard let key = url?.absoluteString else { return nil }
        return downloadTasks.removeValue(forKey: key)
    }
    
}

/**
 Reference:
    - https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Status
    - https://stackoverflow.com/questions/26191377/how-to-check-response-statuscode-in-sendsynchronousrequest-on-swift
    
 HTTP Error Code
    - 200 OK : 请求成功
    - 206 Partial Content : 请求已成功，分段内容
 
    - 401 Unauthorized : 授权出错
    - 404 Not Found : 资源不存在
    - 405 Method Not Allowed : HTTP 方法错误
    - 415 Unsupported Media Type : ContentType 有误
 */

extension ExtWrapper where Base == HTTPURLResponse {
    /// 是否成功响应
    var isSucceeded: Bool { 200 ..< 300 ~= base.statusCode }
    
    /// HTTP 状态描述
    var statusMessage: String {
        var message = ""
        switch base.statusCode {
        case 200: message = "OK"
        case 206: message = "Partial Content"
        
        case 401: message = "Unauthorized"
        case 404: message = "Not Found"
        case 405: message = "Method Not Allowed"
        case 415: message = "Unsupported Media Type"
        
        case 500: message = "Server error"
        default: message = HTTPURLResponse.localizedString(forStatusCode: base.statusCode)
        }
        return message
    }
}
