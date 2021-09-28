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
    public var downloadLogged: Bool = true
    
    /// 下载任务
    struct DownloadTask {
        let startTime = Date()
        
        let url: URL
        let saveUrl: URL
        let stamp: String
        let progress: ProgressHandler?
        let handler: DownloadHandler?
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
    private var downloadTasks = [String: [DownloadTask]]()
}
public extension NetworkManager {
    
    private func url(_ urlString: String, method: HttpMethod, params: Any?, urlEncoded: Bool = true) -> URL? {
        guard let url = URL(string: urlString) else { return nil }
        guard method == .get, let params = params as? [String: Any] else { return url }
        
        guard urlEncoded, var urlComponets = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            var string = urlString
            let keys = params.keys.map({ $0 })
            for i in 0..<keys.count {
                let key = keys[i]
                string.append(i == 0 ? "?" : "&")
                string.append("\(key)=\(params[key] ?? "")")
            }
            return URL(string: string) ?? url
        }
        // GET请求，添加查询参数
        urlComponets.queryItems = params.map({ URLQueryItem(name: $0.key, value: "\($0.value)") })
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
              headers: [String: String]? = nil, headerLogged: Bool = false,
              params: Any? = nil, handler: @escaping DataHandler) {
        
        guard let url = self.url(urlString, method: method, params: params) else {
            Ext.debug("Data HTTP url create failed. \(urlString)", tag: .failure, locationEnabled: false)
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
            if self.headerLogged || headerLogged {
                requestMsg += " | headers: \(headers)"
            }
        }
        // 设置 HTTP 请求体
        /**
         - https://stackoverflow.com/questions/978061/http-get-with-request-body
         - https://stackoverflow.com/questions/56955595/1103-error-domain-nsurlerrordomain-code-1103-resource-exceeds-maximum-size-i
         */
        if method != .get, let params = params,
           let httpBody = try? JSONSerialization.data(withJSONObject: params, options: [.sortedKeys]) {
            request.httpBody = httpBody
            request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
            requestMsg += " | \(httpBody.ext.prettyPrintedJSONString ?? "")"
        }
        
        data(request, msg: requestMsg, handler: handler)
    }
    
    /// 数据请求
    /// - Parameters:
    ///   - request: 请求体
    ///   - requestMsg: 请求日志
    ///   - handler: 数据回调
    private func data(_ request: URLRequest, msg requestMsg: String, handler: @escaping DataHandler) {
        func dataHandler(_ data: Data?, _ response: URLResponse?, _ error: Error?) {
            DispatchQueue.main.async {
                handler((data, response, error))
            }
        }
        
        let requestTime = Date()
        Ext.debug("Data Request | \(requestMsg)", tag: .network, locationEnabled: false)
        DispatchQueue.global(qos: .userInitiated).async {
            let configuration = URLSessionConfiguration.default
            let session = URLSession(configuration: configuration)
            let task = session.dataTask(with: request) { (data, response, error) in
                let elapsed = Date().timeIntervalSince(requestTime)
                var responseMsg = "elapsed : \(String(format: "%.4f", elapsed)) | \(requestMsg)"
                let httpResponse = response as? HTTPURLResponse
                guard httpResponse?.statusCode == 200 else {
                    guard let error = error else {
                        responseMsg += " | statusCcode != 200, \(httpResponse?.statusCode ?? 0) (\(httpResponse?.statusCode.statusMessage ?? ""))"
                        Ext.debug("Data Response failure | \(responseMsg)", tag: .failure, locationEnabled: false)
                        dataHandler(nil, response, Ext.Error.inner("Server error \(httpResponse?.statusCode ?? 0)."))
                        return
                    }
                    responseMsg += " | \(Ext.LogTag.error.token) \(error.localizedDescription)"
                    Ext.debug("Data Response failure | \(responseMsg)", tag: .failure, locationEnabled: false)
                    dataHandler(data, response, error)
                    return
                }
                if let data = data {
                    let rawData = data.ext.prettyPrintedJSONString ?? data.ext.string ?? ""
                    responseMsg += " | \(Ext.LogTag.bingo.token) Data => \(rawData)"
                }
                Ext.debug("Data Response success | \(responseMsg) \n", tag: .success, locationEnabled: false)
                dataHandler(data, response, error)
            }
            task.resume()
        }
    }
}

// MARK: - FormData Upload

/// form-data 文件数据
public struct FormData {
    public init() {}
    /// 附件名字
    public var name: String?
    /// 文件名
    public var filename: String?
    /**
     文件 MIME 类型
     Reference: https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Basics_of_HTTP/MIME_types
     
      - text/plain
      - text/html
      - image/jpeg
      - image/png
      - audio/m4a
      - video/mp4
      - application/json
      - application/javascript
    */
    public var mimeType: String?
    /// 文件数据
    public var data: Data?
}
extension FormData: CustomStringConvertible {
    public var description: String {
        return "{ name: \(name ?? ""), filename: \(filename ?? ""), mimeType: \(mimeType ?? "")}"
    }
}

public extension NetworkManager {
    
    /// formdata 格式上传 (POST)
    /// - Parameters:
    ///   - urlString: 请求 URL
    ///   - params: 请求参数
    ///   - formDatas: 请求 FormData 数据
    ///   - handler: 数据回调
    func upload(_ urlString: String,
                headers: [String: String]? = nil, headerLogged: Bool = false,
                params: [String: Any]? = nil, formDatas: [FormData],
                handler: @escaping DataHandler) {
        guard let url = URL(string: urlString) else {
            Ext.debug("Upload HTTP url create failed. \(urlString)", tag: .failure, locationEnabled: false)
            handler((nil, nil, Ext.Error.inner("http url create failed.")))
            return
        }
        var requestMsg = "FormData upload | \(urlString)"
        
        var request = URLRequest(url: url, timeoutInterval: 60 * 2) // 上传超时时间: 2分钟
        // 设置 HTTP 请求方法
        request.httpMethod = HttpMethod.post.rawValue
        // 设置 HTTP 请求头
        if let headers = headers {
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
            if self.headerLogged || headerLogged {
                requestMsg += " | headers: \(headers)"
            }
        }
        // 设置 HTTP 请求体
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let (httpBody, msg) = createBody(boundary: boundary, params: params, formDatas: formDatas)
        request.httpBody = httpBody
        requestMsg += " | \(msg)"
        
        data(request, msg: requestMsg, handler: handler)
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

// MARK: - Download

public extension NetworkManager {
    
    /// 下载请求
    /// - Parameters:
    ///   - urlString: 下载 Url
    ///   - saveUrl: 保存到本地 Url
    ///   - stamp: 下载标记
    ///   - progress: 下载进度回调
    ///   - handler: 下载数据回调
    @discardableResult func download(urlString: String, saveUrl: URL, stamp: String = "", progress: ProgressHandler? = nil, handler: @escaping DownloadHandler) -> URLSessionDownloadTask? {
        guard let url = URL(string: urlString) else {
            Ext.debug("Download HTTP url create failed. \(urlString)", tag: .failure, logEnabled: downloadLogged, locationEnabled: false)
            handler((nil, Ext.Error.inner("download url create failed.")))
            return nil
        }
        
        let downloadTask = DownloadTask(url: url, saveUrl: saveUrl, stamp: stamp, progress: progress, handler: handler)
        guard append(downloadTask) else {
            Ext.debug("\(url.absoluteString) is downloading...", logEnabled: downloadLogged, locationEnabled: false)
            return nil
        }
        
        Ext.debug("Download Request | \(url.absoluteString)", tag: .network, logEnabled: downloadLogged, locationEnabled: false)
        let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 60 * 5)
        let task = downloadSession.downloadTask(with: request)
        task.resume()
        return task
    }
    
}

extension NetworkManager: URLSessionDownloadDelegate {
    
    /// downloading
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let tasks = tasks(for: downloadTask.currentRequest?.url), totalBytesExpectedToWrite > 0 else { return }
        let date = Date()
        for task in tasks {
            task.progressHandler(date, bytesWritten: bytesWritten, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
        }
    }
    /// download finish
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let tasks = remove(for: downloadTask.currentRequest?.url) else { return }
        let date = Date()
        for task in tasks {
            task.successHandler(date, session: session, downloadTask: downloadTask, didFinishDownloadingTo: location)
        }
    }
    /// download error
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let downloadTasks = remove(for: task.currentRequest?.url) else { return }
        let date = Date()
        for downloadTask in downloadTasks {
            downloadTask.errorHandler(date, session: session, task: task, didCompleteWithError: error)
        }
    }
    
}

private extension NetworkManager {
    
    /// 添加一个下载任务
    /// - Parameter task: 添加任务
    private func append(_ task: DownloadTask) -> Bool {
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
    private func tasks(for url: URL?) -> [DownloadTask]? {
        guard let key = url?.absoluteString else { return nil }
        return downloadTasks[key]
    }
    private func remove(for url: URL?) -> [DownloadTask]? {
        guard let key = url?.absoluteString else { return nil }
        return downloadTasks.removeValue(forKey: key)
    }
}

private extension NetworkManager.DownloadTask {
    
    func progressHandler(_ date: Date, bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let elapsed = date.timeIntervalSince(startTime)
        let progress = Double(totalBytesWritten)/Double(totalBytesExpectedToWrite)
        let speed = Double(totalBytesWritten) / elapsed / 1024
        //Ext.debug("Download start \(startTime) progress: \(progress) | speed: \(speed)", locationEnabled: false)
        self.progress?((progress, speed))
    }
    func successHandler(_ date: Date, session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let downloadUrlString = downloadTask.currentRequest?.url?.absoluteString ?? ""
        let elapsed = date.timeIntervalSince(startTime)
        guard let httpResponse = downloadTask.response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            Ext.debug("Download failure. \(elapsed) | \(downloadUrlString) | statusCode != 200, \((downloadTask.response as? HTTPURLResponse)?.statusCode ?? -110)",
                      tag: .failure, logEnabled: NetworkManager.shared.downloadLogged, locationEnabled: false)
            self.handler?((nil, nil))
            return
        }
        Ext.debug("Download success. \(elapsed) | \(downloadUrlString)",
                  tag: .success, logEnabled: NetworkManager.shared.downloadLogged, locationEnabled: false)
        FileManager.default.ext.save(location, to: saveUrl)
        guard let data = try? Data(contentsOf: saveUrl) else {
            self.handler?((nil, nil))
            return
        }
        self.handler?((data, nil))
    }
    func errorHandler(_ date: Date, session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let elapsed = date.timeIntervalSince(startTime)
        Ext.debug("Download error. \(elapsed) | \(task.currentRequest?.url?.absoluteString ?? "") | \((task.response as? HTTPURLResponse)?.statusCode ?? -110)", error: error,
                  tag: .failure, logEnabled: NetworkManager.shared.downloadLogged, locationEnabled: false)
        self.handler?((nil, error))
    }
    
}

/**
 Reference: https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Status
 HTTP Error Code
    - 401 Unauthorized : 授权出错
    - 404 Not Found : 资源不存在
    - 405 Method Not Allowed : HTTP 方法错误
    - 415 Unsupported Media Type : ContentType 有误
 */

private extension Int {
    var statusMessage: String? {
        switch self {
        case 401: return "Unauthorized"
        case 404: return "Not Found"
        case 405: return "Method Not Allowed"
        case 415: return "Unsupported Media Type"
        default: return ""
        }
    }
}
