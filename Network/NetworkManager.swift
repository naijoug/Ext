//
//  NetworkManager.swift
//  Ext
//
//  Created by naijoug on 2021/3/10.
//

import Foundation

/// HTTP 请求方法
public enum HttpMethod: String {
    case get        = "GET"
    case put        = "PUT"
    case post       = "POST"
    case patch      = "PATCH"
    case delete     = "DELETE"
}

/// 数据回调
public typealias DataHandler = Ext.DataHandler<(Data?, URLResponse?, Error?)>
/// 进度回调
public typealias ProgressHandler = (_ progress: Double, _ speed: Double) -> Void
/// 下载回调
public typealias DownloadHandler = Ext.ResultDataHandler<URL>

/// network manager
public final class NetworkManager: NSObject {
    public static let shared = NetworkManager()
    private override init() {
        super.init()
    }
    
    /// 是否打印日志
    public var logEnabled: Bool = true
    /// 是否打印 HTTP headers 日志
    public var headerLogged: Bool = false
    /// 是否打印下载日志
    public var downloadLogged: Bool = false
    
    /// 下载 Session
    private(set) lazy var downloadSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "DownloadSession")
        let session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
        return session
    }()
    /// 下载队列
    private let downloadQueue = DispatchQueue(label: "DownloadTaskQueue", qos: .utility)
    /// 下载任务列表
    private var downloadTasks = [String: [DownloadTask]]()
}
 
extension NetworkManager {
    
    /// 添加一个下载任务
    func append(_ task: DownloadTask) -> Bool {
        let key = task.url.absoluteString
        var tasks = downloadTasks[key] ?? [DownloadTask]()
        if !tasks.isEmpty, tasks.contains(where: { $0.stamp == task.stamp }) {
            Ext.debug("已经包含该 \(task.stamp) 任务", logEnabled: downloadLogged, locationEnabled: false)
            return false
        }
        tasks.append(task)
        downloadTasks[key] = tasks
        Ext.debug("添加下载任务: \(task.stamp) | \(task.startTime) | \(key)", logEnabled: downloadLogged, locationEnabled: false)
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
 Reference: https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Status
 HTTP Error Code
    - 200 OK : 请求成功
    - 206 Partial Content : 请求已成功，分段内容
 
    - 401 Unauthorized : 授权出错
    - 404 Not Found : 资源不存在
    - 405 Method Not Allowed : HTTP 方法错误
    - 415 Unsupported Media Type : ContentType 有误
 */

extension HTTPURLResponse {
    /// HTTP 状态描述
    var statusMessage: String {
        var message = ""
        switch self.statusCode {
        case 200: message = "OK"
        case 206: message = "Partial Content"
        
        case 401: message = "Unauthorized"
        case 404: message = "Not Found"
        case 405: message = "Method Not Allowed"
        case 415: message = "Unsupported Media Type"
        default: ()
        }
        return "【statusCode == \(self.statusCode)\(message.isEmpty ? "" : " | \(message)")】"
    }
}
