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

/// form-data 文件数据
public struct FormData {
    public init() {}
    /// 附件名字
    public var name: String?
    /// 文件名
    public var filename: String?
    /// 文件 MIME 类型
    public var mimeType: String?
    /// 文件数据
    public var data: Data?
}
extension FormData: CustomStringConvertible {
    public var description: String {
        return "{ name: \(name ?? ""), filename: \(filename ?? ""), mimeType: \(mimeType ?? "")}"
    }
}

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
    
    /// 下载任务
    struct DownloadTask {
        var saveUrl: URL
        var startTime: Date
        var progress: ProgressHandler?
        var handler: DownloadHandler?
    }
    
    /// 数据回调
    public typealias DataHandler = Ext.DataHandler<(Data?, URLResponse?, Error?)>
    /// 进度回调
    public typealias ProgressHandler = Ext.DataHandler<(Double, Double)>
    /// 下载回调
    public typealias DownloadHandler = Ext.DataHandler<(Data?, Error?)>
    
    /// 下载 Session
    private lazy var downloadSession: URLSession = {
        let session = URLSession(configuration: URLSessionConfiguration.background(withIdentifier: "DownloadSession"), delegate: self, delegateQueue: .main)
        return session
    }()
    /// 下载队列
    private let downloadQueue = DispatchQueue(label: "DownloadTaskQueue", qos: .utility)
    /// 下载任务列表
    private var downloadTasks = [String: DownloadTask]()
    
    /// 打印日志
    private func log(_ title: String, msg: String, logEnabled: Bool = true) {
        guard Ext.isDebug, self.logEnabled, logEnabled else { return }
        print("\(title) \(Date().ext.logTime) | \(msg)")
    }
}
public extension NetworkManager {
    
    
    private func url(_ urlString: String, method: HttpMethod, params: [String: Any]?) -> URL? {
        guard let url = URL(string: urlString) else { return nil }
        guard method == .get, let params = params,
              var urlComponets = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url }
        // 添加查询参数
        urlComponets.queryItems = params.map({ URLQueryItem(name: $0.key, value: "\($0.value)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)) })
        return urlComponets.url ?? url
    }
    
    /// 数据获取
    /// - Parameters:
    ///   - urlString: 请求 URL
    ///   - method: 请求 HTTP 方法
    ///   - headers: 请求头
    ///   - httpBody: 请求体
    ///   - handler: 数据回调
    func data(_ urlString: String, method: HttpMethod,
              headers: [String: String]? = nil, params: [String: Any]? = nil,
              handler: @escaping DataHandler) {
        
        guard let url = self.url(urlString, method: method, params: params) else {
            self.log("", msg: "HTTP url create failed. \(urlString)")
            handler((nil, nil, Ext.Error.inner("http url create failed.")))
            return
        }
        
        var request = URLRequest(url: url)
        // 设置 HTTP 请求方法
        request.httpMethod = method.rawValue
        // 根据请求方法，设置组装请求参数
        var requestMsg = "\(method.rawValue) | \(request.url?.absoluteString ?? "")"
        // 设置 HTTP 请求头
        if let headers = headers {
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
            if headerLogged {
                requestMsg += " | headers: \(headers)"
            }
        }
        // 设置 HTTP 请求体
        switch method {
        /**
         - https://stackoverflow.com/questions/978061/http-get-with-request-body
         - https://stackoverflow.com/questions/56955595/1103-error-domain-nsurlerrordomain-code-1103-resource-exceeds-maximum-size-i
         */
        case .get: break
        default:
            if let params = params {
                request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [.prettyPrinted, .sortedKeys])
                requestMsg += " | \(request.httpBody?.ext.prettyPrintedJSONString ?? "")"
            }
        }
        
        data(request, msg: requestMsg, handler: handler)
    }
    
    
    /// formdata 格式上传
    /// - Parameters:
    ///   - urlString: 请求 URL
    ///   - method: 请求方法 (默认: POST)
    ///   - params: 请求参数
    ///   - formDatas: 请求 FormData 数据
    ///   - handler: 数据回调
    func upload(_ urlString: String, method: HttpMethod = .post,
                params: [String: Any]? = nil, formDatas: [FormData],
                handler: @escaping DataHandler) {
        guard let url = URL(string: urlString) else {
            Ext.debug("HTTP url create failed. \(urlString)")
            handler((nil, nil, Ext.Error.inner("http url create failed.")))
            return
        }
        var requestMsg = "\(method.rawValue) | \(urlString)"
        
        var request = URLRequest(url: url, timeoutInterval: 60*2) // 上传超时时间: 2分钟
        // 设置 HTTP 请求方法
        request.httpMethod = method.rawValue
        // 设置 HTTP 请求体
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let (httpBody, msg) = createBody(boundary: boundary, params: params, formDatas: formDatas)
        request.httpBody = httpBody
        requestMsg += " | \(msg)"
        
        data(request, msg: requestMsg, handler: handler)
    }
    
    
    /// 数据请求
    /// - Parameters:
    ///   - request: 请求体
    ///   - requestMsg: 请求日志
    ///   - handler: 数据回调
    private func data(_ request: URLRequest, msg requestMsg: String, handler: @escaping DataHandler) {
        let requestTime = Date()
        log("Data Request ", msg: requestMsg)
        DispatchQueue.global(qos: .userInitiated).async {
            let configuration = URLSessionConfiguration.default
            let session = URLSession(configuration: configuration)
            let task = session.dataTask(with: request) { (data, response, error) in
                let elapsed = Date().timeIntervalSince(requestTime)
                var responseMsg = "elapsed : \(String(format: "%.4f", elapsed)) | \(requestMsg)"
                let httpResponse = response as? HTTPURLResponse
                guard httpResponse?.statusCode == 200 else {
                    guard let error = error else {
                        responseMsg += " | HTTP status code != 200, \(httpResponse?.description ?? "")\n"
                        self.log("Data Response Failed", msg: responseMsg)
                        handler((nil, response, Ext.Error.inner("Server error \(httpResponse?.statusCode ?? 0).")))
                        return
                    }
                    responseMsg += " | Error: \(error.localizedDescription)\n"
                    self.log("Data Response Failed", msg: responseMsg)
                    handler((data, response, error))
                    return
                }
                if let data = data {
                    let rawData = data.ext.prettyPrintedJSONString ?? data.ext.string ?? ""
                    responseMsg += "\n\tData => \(rawData)\n"
                }
                self.log("Data Response Succeed", msg: responseMsg)
                handler((data, response, error))
            }
            task.resume()
        }
    }
    
    /// 创建 multipart/form-data Body 体
    /// - Parameters:
    ///   - boundary: 分界字符
    ///   - params: 参数
    ///   - formDatas: formData 数据
    private func createBody(boundary: String,
                            params: [String: Any]?,
                            formDatas: [FormData]) -> (Data, String) {
        var body = Data()
        var msg = ""
        let lineBreak = "\r\n"
        // boundary 线
        let boundaryPrefix = "--\(boundary)\(lineBreak)"
        // 拼接参数
        if let params = params {
            msg += "params: \(params)"
            for (key, value) in params {
                body.appendString(boundaryPrefix)
                body.appendString("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak)\(lineBreak)")
                body.appendString("\(value)\(lineBreak)")
            }
        }
        // 拼接 multipart 文件
        msg += " | form-data: \(formDatas)"
        for formData in formDatas {
            guard let name = formData.name, let filename = formData.filename,
                  let data = formData.data else { continue }
            body.appendString(boundaryPrefix)
            body.appendString("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\(lineBreak)")
            if let mimeType = formData.mimeType, mimeType != "" {
                body.appendString("Content-Type: \(mimeType)\(lineBreak)\(lineBreak)")
            }
            body.append(data)
            body.appendString("\(lineBreak)")
        }
        // boundary 结束
        body.appendString("--\(boundary)--")
        return (body, msg)
    }
}

fileprivate extension Data {
    /// 添加字符串到 Data
    mutating func appendString(_ string: String) {
        guard let data = string.data(using: .utf8, allowLossyConversion: true) else { return }
        append(data)
    }
}


public extension NetworkManager {
    
    /// 下载请求
    /// - Parameters:
    ///   - urlString: 下载 Url
    ///   - saveUrl: 保存到本地 Url
    ///   - progress: 下载进度回调
    ///   - handler: 下载数据回调
    @discardableResult func download(urlString: String, saveUrl: URL, progress: ProgressHandler? = nil, handler: @escaping DownloadHandler) -> URLSessionDownloadTask? {
        guard let url = URL(string: urlString) else {
            Ext.debug("HTTP url create failed. \(urlString)")
            handler((nil, Ext.Error.inner("download url create failed.")))
            return nil
        }
        
        if task(for: url) != nil {
            Ext.debug("\(url.absoluteString) is downloading...")
            return nil
        }
        
        let downloadTask = DownloadTask(saveUrl: saveUrl, startTime: Date(), progress: progress, handler: handler)
        append(downloadTask, for: url)
        
        let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 60*10)
        let task = downloadSession.downloadTask(with: request)
        task.resume()
        return task
    }
    
    private func append(_ task: DownloadTask, for url: URL?) {
        guard let key = url?.absoluteString else { return }
        downloadTasks[key] = task
    }
    private func task(for url: URL?) -> DownloadTask? {
        guard let key = url?.absoluteString else { return nil }
        return downloadTasks[key]
    }
    private func remove(for url: URL?) -> DownloadTask? {
        guard let key = url?.absoluteString else { return nil }
        return downloadTasks.removeValue(forKey: key)
    }
}
extension NetworkManager: URLSessionDownloadDelegate {
    
    /// downloading
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let task = task(for: downloadTask.currentRequest?.url), totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten)/Double(totalBytesExpectedToWrite)
        let elapsed = Date().timeIntervalSince(task.startTime)
        let speed = Double(totalBytesWritten) / elapsed
        task.progress?((progress, speed))
        Ext.debug("download progress: \(progress) | speed: \(speed)", logEnabled: downloadLogged)
    }
    /// download succeed
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let task = remove(for: downloadTask.currentRequest?.url) else { return }
        guard let httpResponse = downloadTask.response as? HTTPURLResponse else { return }
    
        let elapsed = Date().timeIntervalSince(task.startTime)
        Ext.debug("download success. \(elapsed)", logEnabled: downloadLogged)
        guard httpResponse.statusCode == 200 else {
            let msg = httpResponse.statusCode == 404 ? "resource not found." : httpResponse.description
            Ext.debug("download status code != 200 | \(httpResponse.statusCode) | \(msg)")
            task.handler?((nil, nil))
            return
        }
        FileManager.default.ext.save(location, to: task.saveUrl)
        guard let data = try? Data(contentsOf: task.saveUrl) else {
            task.handler?((nil, nil))
            return
        }
        task.handler?((data, nil))
    }
    /// download failed
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let downloadTask = remove(for: task.currentRequest?.url) else { return }
        guard let httpResponse = task.response as? HTTPURLResponse else { return }
        
        let elapsed = Date().timeIntervalSince(downloadTask.startTime)
        Ext.debug("download failed. \(elapsed) | \(httpResponse.statusCode) | Error: \(error?.localizedDescription ?? "")")
        downloadTask.handler?((nil, error))
    }
    
}
