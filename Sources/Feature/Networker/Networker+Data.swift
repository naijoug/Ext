//
//  Networker+Data.swift
//  Ext
//
//  Created by guojian on 2021/11/12.
//  网络 - 数据请求

import Foundation

/// 数据请求协议
public protocol DataRequestType {
    var urlRequest: URLRequest? { get }
    
    /// 附加日志
    func appendLog() -> String?
}
public extension DataRequestType {
    func appendLog() -> String? { nil }
}

public extension DataRequestType {
    /// 请求数据
    /// - Parameters:
    ///   - queue: 数据响应所在的队列 (默认: 主队列)
    ///   - handler: 数据响应回调
    @discardableResult
    func data(queue: DispatchQueue = .main, handler: @escaping Ext.ResultDataHandler<(response: HTTPURLResponse, data: Data)>) -> URLSessionDataTask? {
        guard let request = urlRequest else {
            handler(.failure(Networker.Error.invalidURL))
            return nil
        }
        return Networker.shared.data(queue: queue, request: request, appendLog: appendLog(), handler: handler)
    }
}

// MARK: -

public extension Networker {
    /// 数据请求
    /// - Parameters:
    ///   - queue: 数据响应所在的队列 (默认: 主队列)
    ///   - request: 请求体
    ///   - appendLog: 请求体附加日志
    ///   - handler: 数据响应
    @discardableResult
    func data(queue: DispatchQueue = .main, request: URLRequest, appendLog: String? = nil,
              handler: @escaping Ext.ResultDataHandler<(response: HTTPURLResponse, data: Data)>) -> URLSessionDataTask {
        let requestTime = Date()
        let requestLog = request.ext.log + (appendLog ?? "")
        let logEnabled = self.logEnabled
        Ext.debug("Data Request | \(requestLog)", tag: .network, logEnabled: logEnabled, locationEnabled: false)
        let task = dataSession.dataTask(with: request) { (data, response, error) in
            let elapsed = Date().timeIntervalSince(requestTime)
            
            var responseLog = "elapsed : \(String(format: "%.4f", elapsed)) / \(request.timeoutInterval) | \(requestLog)"
            
            guard let response = response, let data = data else {
                Ext.debug("Data Response failed. | \(responseLog) \n", error: error, tag: .failure, logEnabled: logEnabled, locationEnabled: false)
                queue.async { handler(.failure(Ext.Error.error(error ?? Networker.Error.noResponseData))) }
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                responseLog += " | not http response"
                Ext.debug("Data Response failed. | \(responseLog) \n", error: error, tag: .failure, logEnabled: logEnabled, locationEnabled: false)
                queue.async { handler(.failure(Networker.Error.nonHTTPResponse(response: response))) }
                return
            }
            let dataString = data.ext.toJSONString() ?? data.ext.string ?? ""
            responseLog += " | \(httpResponse.ext.isSucceeded ? "✅" : "❎【\(httpResponse.statusCode) - \(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))】") Data => \(dataString)"
            Ext.debug("Data Response | \(responseLog) \n", tag: .ok, locationEnabled: false)
            queue.async { handler(.success((httpResponse, data))) }
        }
        task.resume()
        return task
    }
}

public extension Networker {
    /// 数据请求
    struct DataRequest {
        /// 请求地址
        let urlString: String
        /// 请求 HTTP 方法
        let method: HttpMethod
        /// 请求头
        let headers: [String: String]?
        /// 请求参数
        let params: Any?
        /// 请求超时时间 (默认: 60s)
        let timeoutInterval: TimeInterval
        
        public init(_ urlString: String, method: HttpMethod = .get, headers: [String: String]? = nil, params: Any? = nil, timoutInterval: TimeInterval = 60.0) {
            self.urlString = urlString
            self.method = method
            self.headers = headers
            self.params = params
            self.timeoutInterval = timoutInterval
        }
    }
}
extension Networker.DataRequest: DataRequestType {
    
    public var urlRequest: URLRequest? {
        guard let url = self.url() else {
            Ext.debug("Data HTTP URL init failed. \(urlString)", tag: .failure, locationEnabled: false)
            return nil
        }
        
        var request = URLRequest(url: url, timeoutInterval: timeoutInterval)
        // 设置 HTTP 请求方法
        request.httpMethod = method.rawValue
        // 设置 HTTP 请求头
        for (key, value) in headers ?? [:] {
            request.addValue(value, forHTTPHeaderField: key)
        }
        // 设置 HTTP 请求体
        /**
         - https://stackoverflow.com/questions/978061/http-get-with-request-body
         - https://stackoverflow.com/questions/56955595/1103-error-domain-nsurlerrordomain-code-1103-resource-exceeds-maximum-size-i
         */
        if let params = params {
            switch method {
            case .get: ()
            default:
                if let httpBody = try? JSONSerialization.data(withJSONObject: params, options: [.sortedKeys]) {
                    request.httpBody = httpBody
                    request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
                }
            }
        }
        return request
    }
    
    private func url(urlEncoded: Bool = true) -> URL? {
        guard let url = URL(string: urlString) else { return nil }
        // GET 请求添加请求参数
        guard method == .get, let params = params as? [String: Any], !params.isEmpty else { return url }
        
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
}

// MARK: - FormData

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

public extension Networker {
    /// form-data 格式数据请求
    struct FormDataRequest {
        /// 请求地址
        let urlString: String
        /// form-data 数据
        let formDatas: [FormData]
        /// 请求头
        let headers: [String: String]?
        /// 请求参数
        let params: [String: Any]?
        /// 请求超时时间 (默认: 120s)
        let timeoutInterval: TimeInterval
        
        public init(_ urlString: String, formDatas: [FormData], headers: [String: String]? = nil, params: [String: Any]? = nil, timoutInterval: TimeInterval = 120.0) {
            self.urlString = urlString
            self.formDatas = formDatas
            self.headers = headers
            self.params = params
            self.timeoutInterval = timoutInterval
        }
    }
}

extension Networker.FormDataRequest: DataRequestType {
        
    public var urlRequest: URLRequest? {
        guard let url = URL(string: urlString) else {
            Ext.debug("FormData HTTP URL init failed. \(urlString)", tag: .failure, locationEnabled: false)
            return nil
        }
        
        var request = URLRequest(url: url, timeoutInterval: timeoutInterval)
        // 设置 HTTP 请求方法 (form-data 使用: POST)
        request.httpMethod = HttpMethod.post.rawValue
        // 设置 HTTP 请求头
        for (key, value) in headers ?? [:] {
            request.addValue(value, forHTTPHeaderField: key)
        }
        // 设置 HTTP 请求体
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody(boundary: boundary)
        return request
    }
    
    public func appendLog() -> String? {
        var log = ""
        if let params = params, !params.isEmpty {
            log += " | params: \(params)"
        }
        log += " | form-data: \(formDatas)"
        return log
    }
    
    /// 创建 multipart/form-data Body 体
    /// - Parameters:
    ///   - boundary: 分界字符
    private func httpBody(boundary: String) -> Data {
        var body = Data()
        let lineBreak = "\r\n"
        // boundary 线
        let boundaryPrefix = "--\(boundary)\(lineBreak)"
        // 拼接参数
        for (key, value) in params ?? [:] {
            body.appendString(boundaryPrefix)
            body.appendString("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak)\(lineBreak)")
            body.appendString("\(value)\(lineBreak)")
        }
        // 拼接 multipart 文件
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
        return body
    }
}

private extension Data {
    /// 添加字符串到 Data
    mutating func appendString(_ string: String) {
        guard let data = string.data(using: .utf8, allowLossyConversion: true) else { return }
        append(data)
    }
}

// MARK: - Ext

public extension Swift.Result where Success == (response: HTTPURLResponse, data: Data) {
    /**
     http response result ---> data result
     将非正确响应状态码 (statusCode != 200 ~ 299) 转化为错误
     */
    func asData() -> Swift.Result<Data, Swift.Error> {
        switch self {
        case .failure(let error): return .failure(error)
        case .success(let tuple):
            guard tuple.response.ext.isSucceeded else {
                return .failure(Networker.Error.httpResponseFailed(response: tuple.response, data: tuple.data))
            }
            return .success(tuple.data)
        }
    }
}
public extension Swift.Result where Success == Data {
    /// data result ---> json result
    func asJSON(_ options: JSONSerialization.ReadingOptions = [.fragmentsAllowed, .allowFragments]) -> Swift.Result<Any, Swift.Error> {
        switch self {
        case .failure(let error): return .failure(error)
        case .success(let data):
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: options)
                return .success(json)
            } catch {
                return .failure(Networker.Error.jsonDeserializationError(error: error))
            }
        }
    }
    /// data result ---> string result
    func asString() -> Swift.Result<String?, Swift.Error> {
        switch self {
        case .failure(let error): return .failure(error)
        case .success(let data): return .success(String(data: data, encoding: .utf8))
        }
    }
}

extension URLRequest: ExtCompatible {}
private extension ExtWrapper where Base == URLRequest {
    /// URL Request log
    var log: String {
        var log = "\(base.httpMethod ?? "GET") | \(base.url?.absoluteString.removingPercentEncoding ?? "")"
        if Networker.shared.headerLogged, let headers = base.allHTTPHeaderFields, !headers.isEmpty {
            log += " | headers: \(headers)"
        }
        if let httpBody = base.httpBody?.ext.toJSONString(errorLogged: false) ?? base.httpBody?.ext.string {
            log += " | \(httpBody)"
        }
        return log
    }
}
