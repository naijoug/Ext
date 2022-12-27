//
//  Networker+Data.swift
//  Ext
//
//  Created by guojian on 2021/11/12.
//  网络 - 数据请求

import Foundation

public extension Networker {
    /// 数据请求
    /// - Parameters:
    ///   - queue: 数据响应所在的队列 (默认: 主队列)
    ///   - request: 请求体
    ///   - requestLog: 求体日志
    ///   - handler: 数据响应
    @discardableResult
    func data(queue: DispatchQueue = .main, request: URLRequest, requestLog: String? = nil, handler: @escaping DataHandler) -> URLSessionDataTask {
        let requestTime = Date()
        let requestLog = request.log + (requestLog ?? "")
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
            
            guard httpResponse.ext.isSucceeded else {
                Ext.debug("Data Response failed. | http response failed. \(httpResponse.statusCode) - \(httpResponse.ext.statusMessage)", tag: .failure, logEnabled: logEnabled, locationEnabled: false)
                queue.async { handler(.failure(Networker.Error.httpResponseFailed(response: httpResponse, data: data))) }
                return
            }
            queue.async { handler(.success((httpResponse, data))) }
        }
        task.resume()
        return task
    }
}
private extension URLRequest {
    /// URL Request log
    var log: String {
        var log = "\(httpMethod ?? "GET") | \(url?.absoluteString.removingPercentEncoding ?? "")"
        if Networker.shared.headerLogged, let headers = allHTTPHeaderFields, !headers.isEmpty {
            log += " | headers: \(headers)"
        }
        if let httpBody = httpBody?.ext.toJSONString(errorLogged: false) ?? httpBody?.ext.string {
            log += " | \(httpBody)"
        }
        return log
    }
}

// MARK: - Protocol

public protocol Requestable {
    var baseURLString: String { get }
    var path: String { get }
    var queryParameters: [String: Any] { get }
    var httpMethod: HttpMethod { get }
    var httpHeaderFields: [String: String] { get }
    var contentType: String { get }
    var httpBody: Data? { get }
    var timeoutInterval: TimeInterval { get }
}
public extension Requestable {
    
    @discardableResult
    /// 数据请求
    /// - Parameters:
    ///   - queue: 数据响应所在的队列 (默认: 主队列)
    ///   - handler: 数据响应
    /// - Returns: 数据请求回话任务
    func data(queue: DispatchQueue = .main, handler: @escaping DataHandler) -> URLSessionDataTask? {
        guard let request = urlRequest else {
            handler(.failure(Networker.Error.invalidURL))
            return nil
        }
        return Networker.shared.data(queue: queue, request: request, requestLog: (self as? FormDataRequestable)?.log, handler: handler)
    }
}
private extension Requestable {
    var urlRequest: URLRequest? {
        guard let url = self.url() else {
            Ext.debug("Data HTTP URL init failed. \(urlString)", tag: .failure, locationEnabled: false)
            return nil
        }
        
        var request = URLRequest(url: url, timeoutInterval: timeoutInterval)
        // 设置 HTTP 请求方法
        request.httpMethod = httpMethod.rawValue
        // 设置 HTTP 请求头
        for (key, value) in httpHeaderFields {
            request.addValue(value, forHTTPHeaderField: key)
        }
        // 设置 HTTP Content-Type
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        // 设置 HTTP 请求体
        /**
         - https://stackoverflow.com/questions/978061/http-get-with-request-body
         - https://stackoverflow.com/questions/56955595/1103-error-domain-nsurlerrordomain-code-1103-resource-exceeds-maximum-size-i
         */
        request.httpBody = httpBody
        return request
    }
    
    private var urlString: String {
        guard !path.isEmpty else { return baseURLString }
        return baseURLString + (path.hasPrefix("/") ? path : "/\(path)")
    }
    private func url(urlEncoded: Bool = true) -> URL? {
        guard let url = URL(string: urlString) else { return nil }
        guard !queryParameters.isEmpty else { return url }
        guard urlEncoded, var urlComponets = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            var string = urlString
            let keys = queryParameters.keys.map({ $0 })
            for i in 0..<keys.count {
                let key = keys[i]
                string.append(i == 0 ? "?" : "&")
                string.append("\(key)=\(queryParameters[key] ?? "")")
            }
            return URL(string: string) ?? url
        }
        // GET请求，添加查询参数
        urlComponets.queryItems = queryParameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
        return urlComponets.url ?? url
    }
}

public protocol JSONRequestable: Requestable {
    var jsonParameters: Any? { get }
}
extension JSONRequestable {
    public var jsonParameters: Any? { nil }
    
    public var path: String { "" }
    public var queryParameters: [String: Any] { [:] }
    public var httpMethod: HttpMethod { .get }
    public var httpHeaderFields: [String: String] { [:] }
    public var contentType: String { "application/json; charset=UTF-8" }
    public var httpBody: Data? {
        guard let jsonParameters = jsonParameters,
              let data = try? JSONSerialization.data(withJSONObject: jsonParameters, options: [.sortedKeys]) else { return nil }
        Ext.debug("")
        return data
    }
    public var timeoutInterval: TimeInterval { 60.0 }
}

public protocol FormDataRequestable: Requestable {
    var multipartForm: MultipartForm { get }
}
extension FormDataRequestable {
    public var path: String { "" }
    public var queryParameters: [String: Any] { [:] }
    public var httpMethod: HttpMethod { .post }
    public var httpHeaderFields: [String: String] { [:] }
    public var contentType: String { "multipart/form-data; boundary=\(multipartForm.boundary)" }
    public var httpBody: Data? { multipartForm.httpBody }
    public var timeoutInterval: TimeInterval { 120.0 }
    
    var log: String? { multipartForm.log }
}

public struct MultipartForm {
    /// form-data 文件数据
    public struct FormData {
        /// 附件名字
        public let name: String
        /// 文件名
        public let filename: String
        /// 文件数据
        public var data: Data
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
        public var mimeType: String
        
        public init(name: String, filename: String, data: Data, mimeType: String) {
            self.name = name
            self.filename = filename
            self.data = data
            self.mimeType = mimeType
        }
    }
    
    public let parameters: [String: Any]
    public let formDatas: [FormData]
    public let boundary: String
    public init(parameters: [String: Any], formDatas: [FormData], boundary: String = "Boundary-\(UUID().uuidString)") {
        self.parameters = parameters
        self.formDatas = formDatas
        self.boundary = boundary
    }
}
extension MultipartForm.FormData: CustomStringConvertible {
    public var description: String {
        return "{ name: \(name), filename: \(filename), mimeType: \(mimeType)}"
    }
}
private extension MultipartForm {
    var httpBody: Data {
        var body = Data()
        let lineBreak = "\r\n"
        // boundary 线
        let boundaryPrefix = "--\(boundary)\(lineBreak)"
        // 拼接参数
        for (key, value) in parameters {
            body.appendString(boundaryPrefix)
            body.appendString("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak)\(lineBreak)")
            body.appendString("\(value)\(lineBreak)")
        }
        // 拼接 multipart 文件
        for formData in formDatas {
            body.appendString(boundaryPrefix)
            body.appendString("Content-Disposition: form-data; name=\"\(formData.name)\"; filename=\"\(formData.filename)\"\(lineBreak)")
            body.appendString("Content-Type: \(formData.mimeType)\(lineBreak)\(lineBreak)")
            body.append(formData.data)
            body.appendString("\(lineBreak)")
        }
        // boundary 结束
        body.appendString("--\(boundary)--")
        Ext.debug("")
        return body
    }
    
    var log: String {
        var log = " | multipart/form-data =>"
        log += parameters.isEmpty ? "" : " parameters: \(parameters)"
        log += formDatas.isEmpty ? "" : " formDatas: \(formDatas)"
        Ext.debug("")
        return log
    }
}
private extension Data {
    /// 添加字符串到 Data
    mutating func appendString(_ string: String) {
        guard let data = string.data(using: .utf8, allowLossyConversion: true) else { return }
        append(data)
    }
}
