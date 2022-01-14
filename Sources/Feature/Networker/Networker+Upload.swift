//
//  Networker+Upload.swift
//  Ext
//
//  Created by guojian on 2021/11/12.
//  网络 - 数据下载

import Foundation

// MARK: FormData Upload

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
    
    /// formdata 格式上传 (POST)
    /// - Parameters:
    ///   - urlString: 请求 URL
    ///   - params: 请求参数
    ///   - formDatas: 请求 FormData 数据
    ///   - handler: 数据回调
    @discardableResult
    func upload(_ urlString: String,
                headers: [String: String]? = nil, headerLogged: Bool = false,
                params: [String: Any]? = nil, formDatas: [FormData],
                handler: @escaping DataHandler) -> URLSessionDataTask? {
        guard let url = URL(string: urlString) else {
            Ext.debug("Upload HTTP url create failed. \(urlString)", tag: .failure, locationEnabled: false)
            handler((nil, nil, Ext.Error.inner("http url create failed.")))
            return nil
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
        
        return data(request, msg: requestMsg, handler: handler)
    }
    
}

extension Networker {
    
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
