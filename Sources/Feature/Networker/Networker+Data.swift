//
//  Networker+Data.swift
//  Ext
//
//  Created by guojian on 2021/11/12.
//  网络 - 数据请求

import Foundation

public extension Ext {
    /// 数据请求响应
    struct DataResponse {
        /// HTTP 响应
        public let response: HTTPURLResponse
        /// 请求数据
        public let data: Data
    }
}

/// 请求响应回调
public typealias ResponseHandler = Ext.ResultDataHandler<Ext.DataResponse>

public extension Networker {
    /// 数据请求
    /// - Parameters:
    ///   - queue: 数据响应所在的队列 (默认: 主队列)
    ///   - request: 请求体
    ///   - requestLog: 请体日志
    ///   - responseHandler: 请求响应
    @discardableResult
    func data(queue: DispatchQueue = .main, request: URLRequest, requestLog: String? = nil, responseHandler: @escaping ResponseHandler) -> URLSessionDataTask {
        func result(_ result: Swift.Result<Ext.DataResponse, Swift.Error>) {
            queue.async {
                responseHandler(result)
            }
        }
        
        let requestTime = Date()
        let requestLog = request.log + ((requestLog?.isEmpty ?? true) ? "" : " | \(requestLog ?? "")")
        let logEnabled = self.logEnabled
        Ext.debug("Data Request | \(requestLog)", tag: .network, logEnabled: logEnabled, locationEnabled: false)
        let task = dataSession.dataTask(with: request) { (data, response, error) in
            let elapsed = Date().timeIntervalSince(requestTime)
            
            var responseLog = "elapsed : \(String(format: "%.4f", elapsed)) / \(request.timeoutInterval) | \(requestLog)"
            
            guard let response = response, let data = data else {
                Ext.debug("Data Response failed. | \(responseLog) \n", error: error, tag: .failure, logEnabled: logEnabled, locationEnabled: false)
                result(.failure(Ext.Error.error(error ?? Networker.Error.noResponseData)))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                responseLog += " | not http response"
                Ext.debug("Data Response failed. | \(responseLog) \n", error: error, tag: .failure, logEnabled: logEnabled, locationEnabled: false)
                result(.failure(Networker.Error.nonHTTPResponse(response: response)))
                return
            }
            let dataString = data.ext.toJSONString() ?? data.ext.string ?? ""
            responseLog += " | \(httpResponse.ext.isSucceeded ? "✅" : "❎【\(httpResponse.statusCode) - \(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))】") Data => \(dataString)"
            Ext.debug("Data Response | \(responseLog) \n", tag: .ok, locationEnabled: false)
            
            guard httpResponse.ext.isSucceeded else {
                Ext.debug("Data Response failed. | http response failed. \(httpResponse.statusCode) - \(httpResponse.ext.statusMessage)", tag: .failure, logEnabled: logEnabled, locationEnabled: false)
                result(.failure(Networker.Error.httpResponseFailed(response: httpResponse, data: data)))
                return
            }
            result(.success(Ext.DataResponse(response: httpResponse, data: data)))
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
