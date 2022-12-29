//
//  Requestable.swift
//  Ext
//
//  Created by guojian on 2022/12/28.
//

import Foundation

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
    var path: String { "" }
    var queryParameters: [String: Any] { [:] }
    var httpMethod: HttpMethod { .get }
    var httpHeaderFields: [String: String] { [:] }
    var contentType: String { "" }
    var httpBody: Data? { nil }
    var timeoutInterval: TimeInterval { 60.0 }
}
public extension Requestable {
    @discardableResult
    /// 数据请求响应
    /// - Parameters:
    ///   - queue: 数据响应所在的队列 (默认: 主队列)
    ///   - handler: 数据响应
    /// - Returns: 数据请求回话任务
    func response(queue: DispatchQueue = .main, handler: @escaping ResponseHandler) -> URLSessionDataTask? {
        guard let request = urlRequest else {
            handler(.failure(Networker.Error.invalidURL))
            return nil
        }
        return Networker.shared.data(queue: queue, request: request, requestLog: (self as? Logable)?.log ?? "", responseHandler: handler)
    }
    
    @discardableResult
    /// 数据请求
    /// - Parameters:
    ///   - queue: 数据响应所在的队列 (默认: 主队列)
    ///   - handler: 数据响应
    /// - Returns: 数据请求回话任务
    func data(queue: DispatchQueue = .main, handler: @escaping Ext.ResultDataHandler<Data>) -> URLSessionDataTask? {
        response(queue: queue) { result in
            switch result {
            case .failure(let error): handler(.failure(error))
            case .success(let response): handler(.success(response.data))
            }
        }
    }
}
public extension ExtWrapper where Base: Requestable {
    @discardableResult
    /// 数据请求响应
    /// - Parameters:
    ///   - queue: 数据响应所在的队列 (默认: 主队列)
    ///   - handler: 数据响应
    /// - Returns: 数据请求回话任务
    func response(queue: DispatchQueue = .main, handler: @escaping ResponseHandler) -> URLSessionDataTask? {
        guard let request = base.urlRequest else {
            handler(.failure(Networker.Error.invalidURL))
            return nil
        }
        return Networker.shared.data(queue: queue, request: request, requestLog: (self as? Logable)?.log ?? "", responseHandler: handler)
    }
    
    @discardableResult
    /// 数据请求
    /// - Parameters:
    ///   - queue: 数据响应所在的队列 (默认: 主队列)
    ///   - handler: 数据响应
    /// - Returns: 数据请求回话任务
    func data(queue: DispatchQueue = .main, handler: @escaping Ext.ResultDataHandler<Data>) -> URLSessionDataTask? {
        response(queue: queue) { result in
            switch result {
            case .failure(let error): handler(.failure(error))
            case .success(let response): handler(.success(response.data))
            }
        }
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
        if !contentType.isEmpty {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
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
        /**
         - https://stackoverflow.com/questions/611906/http-post-with-url-query-parameters-good-idea-or-not
         - https://stackoverflow.com/questions/38720933/whats-the-difference-between-passing-false-and-true-to-resolvingagainstbaseurl
         */
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

// MARK: - JSON

public protocol JSONRequestable: Requestable {
    var jsonParameter: Any? { get }
}
public extension JSONRequestable {
    var jsonParameter: Any? { nil }
    
    var queryParameters: [String: Any] {
        guard httpMethod == .get else { return [:] }
        return (jsonParameter as? [String: Any]) ?? [:]
    }
    var contentType: String { "application/json; charset=UTF-8" }
    var httpBody: Data? {
        guard httpMethod != .get else { return nil }
        return parameterData
    }
    
    /// 参数数据
    var parameterData: Data? {
        guard let jsonParameter = jsonParameter,
              let data = try? JSONSerialization.data(withJSONObject: jsonParameter, options: [.sortedKeys]) else { return nil }
        return data
    }
}

// MARK: - Codable

public protocol EncodeRequestable: Requestable {
    var parameter: Encodable? { get }
}
public extension EncodeRequestable {
    var parameter: Encodable? { nil }
    
    var queryParameters: [String: Any] {
        guard httpMethod == .get else { return [:] }
        return (parameterData?.ext.toJSONObject() as? [String: Any]) ?? [:]
    }
    var contentType: String { "application/json; charset=UTF-8" }
    var httpBody: Data? {
        guard httpMethod != .get else { return nil }
        return parameterData
    }
    
    /// 参数数据
    var parameterData: Data? {
        guard let parameter = parameter else { return nil }
        return (try? JSONEncoder().encode(parameter))
    }
}

// MARK: - FormData

public protocol FormDataRequestable: Requestable, Logable {
    var boundary: String { get set }
    var formData: MultipartFormData { get }
}
public extension FormDataRequestable {
    var httpMethod: HttpMethod { .post }
    var contentType: String { "multipart/form-data; boundary=\(boundary)" }
    var httpBody: Data? { formData.httpBody(boundary: boundary) }
    var timeoutInterval: TimeInterval { 120.0 }
    
    var log: String { formData.description }
}

/// multipart/form-data 数据
public struct MultipartFormData {
    /// 文件数据
    public struct FileData {
        /// 附件名字
        public let name: String
        /// 文件名
        public let filename: String
        /// 文件数据
        public var file: Data
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
            self.file = data
            self.mimeType = mimeType
        }
    }
    
    /// form-data 文本数据
    public let textFields: [String: Any]
    /// form-data 文件数据
    public let fileDatas: [FileData]
    public init(textFields: [String: Any], fileDatas: [FileData]) {
        self.textFields = textFields
        self.fileDatas = fileDatas
    }
}
public extension MultipartFormData {
    func httpBody(boundary: String) -> Data {
        var body = Data()
        let lineBreak = "\r\n"
        // boundary 线
        let boundaryPrefix = "--\(boundary)\(lineBreak)"
        // 拼接文本数据
        for (key, value) in textFields {
            body.appendString(boundaryPrefix)
            body.appendString("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak)\(lineBreak)")
            body.appendString("\(value)\(lineBreak)")
        }
        // 拼接文件数据
        for fileData in fileDatas {
            body.appendString(boundaryPrefix)
            body.appendString("Content-Disposition: form-data; name=\"\(fileData.name)\"; filename=\"\(fileData.filename)\"\(lineBreak)")
            body.appendString("Content-Type: \(fileData.mimeType)\(lineBreak)\(lineBreak)")
            body.append(fileData.file)
            body.appendString("\(lineBreak)")
        }
        // boundary 结束
        body.appendString("--\(boundary)--")
        Ext.debug("")
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

extension MultipartFormData: CustomStringConvertible {
    public var description: String {
        """
        {
            "textFields": \(textFields),
            "fileDatas": \(fileDatas)
        }
        """
    }
}
extension MultipartFormData.FileData: CustomStringConvertible {
    public var description: String {
        "{ name: \(name), filename: \(filename), mimeType: \(mimeType)}"
    }
}
