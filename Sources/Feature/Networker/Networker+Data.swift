//
//  Networker+Data.swift
//  Ext
//
//  Created by guojian on 2021/11/12.
//  网络 - 数据请求

import Foundation

public extension Networker {
    
    /// 数据获取
    /// - Parameters:
    ///   - urlString: 请求 URL
    ///   - method: 请求 HTTP 方法
    ///   - headers: 请求头
    ///   - httpBody: 请求体
    ///   - handler: 数据回调
    @discardableResult
    func data(_ urlString: String, method: HttpMethod,
              headers: [String: String]? = nil, headerLogged: Bool = false,
              params: Any? = nil, timeoutInterval: TimeInterval = 60.0, handler: @escaping DataHandler) -> URLSessionDataTask? {
        
        guard let url = self.url(urlString, method: method, params: params) else {
            Ext.debug("Data HTTP url create failed. \(urlString)", tag: .failure, locationEnabled: false)
            handler((nil, nil, Ext.Error.inner("http url create failed.")))
            return nil
        }
        
        var request = URLRequest(url: url, timeoutInterval: timeoutInterval)
        // 设置 HTTP 请求方法
        request.httpMethod = method.rawValue
        // 根据请求方法，设置组装请求参数
        var requestMsg = "\(method.rawValue) | \(request.url?.absoluteString.removingPercentEncoding ?? "")"
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
            requestMsg += " | \(httpBody.ext.toJSONString() ?? "")"
        }
        
        return data(request, msg: requestMsg, handler: handler)
    }
    
}

extension Networker {
    
    /// 创建请求 URL
    private func url(_ urlString: String, method: HttpMethod, params: Any?, urlEncoded: Bool = true) -> URL? {
        guard let url = URL(string: urlString) else { return nil }
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
    
    /// 数据请求
    /// - Parameters:
    ///   - request: 请求体
    ///   - requestMsg: 请求日志
    ///   - handler: 数据回调
    @discardableResult
    func data(_ request: URLRequest, msg requestMsg: String, handler: @escaping DataHandler) -> URLSessionDataTask? {
        func dataHandler(_ data: Data?, _ response: URLResponse?, _ error: Error?) {
            DispatchQueue.main.async {
                handler((data, response, error))
            }
        }
        
        let requestTime = Date()
        Ext.debug("Data Request | \(requestMsg)", tag: .network, locationEnabled: false)
        
        let task = dataSession.dataTask(with: request) { (data, response, error) in
            let elapsed = Date().timeIntervalSince(requestTime)
            let httpResponse = response as? HTTPURLResponse
            var responseMsg = "elapsed : \(String(format: "%.4f", elapsed)) / \(request.timeoutInterval) | \(requestMsg)"
            guard httpResponse?.isResponseOK ?? false else {
                guard let error = error else {
                    responseMsg += " | \(httpResponse?.statusMessage ?? "")"
                    Ext.debug("Data Response failed. | \(responseMsg)", tag: .failure, locationEnabled: false)
                    dataHandler(nil, response, Ext.Error.inner("Server error \(httpResponse?.statusCode ?? 0)."))
                    return
                }
                Ext.debug("Data Response error. | \(responseMsg)", error: error, tag: .failure, locationEnabled: false)
                dataHandler(data, response, error)
                return
            }
            if let data = data {
                let rawData = data.ext.toJSONString() ?? data.ext.string ?? ""
                responseMsg += " | \(Ext.Tag.basketball) Data => \(rawData)"
            }
            Ext.debug("Data Response succeeded | \(responseMsg) \n", tag: .success, locationEnabled: false)
            dataHandler(data, response, nil)
        }
        task.resume()
        return task
    }
    
}
