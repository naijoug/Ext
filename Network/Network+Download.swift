//
//  Network+Download.swift
//  Ext
//
//  Created by guojian on 2021/11/12.
//  网络 - 数据下载

import Foundation

/**
 Reference:
    - https://stackoverflow.com/questions/32322386/how-to-download-multiple-files-sequentially-using-nsurlsession-downloadtask-in-s
 */

/// 下载任务
struct DownloadTask {
    let startTime = Date()
    
    /// 请求链接 URL
    let url: URL
    /// 缓存路径 URL
    let cacheUrl: URL?
    /// 下载时间戳
    let stamp: String
    /// 下载进度回调
    let progress: ProgressHandler?
    /// 下载结果回调
    let handler: DownloadHandler
}

public extension NetworkManager {
    
    /// 下载请求
    /// - Parameters:
    ///   - urlString: 下载链接 Url
    ///   - cacheUrl: 缓存本地 Url
    ///   - stamp: 下载标记
    ///   - progress: 下载进度回调
    ///   - handler: 下载数据回调
    @discardableResult
    func download(urlString: String, cacheUrl: URL?, stamp: String = "", progress: ProgressHandler? = nil, handler: @escaping DownloadHandler) -> URLSessionDownloadTask? {
        guard let url = URL(string: urlString) else {
            Ext.debug("Download HTTP url create failed. \(urlString)", tag: .failure, logEnabled: downloadLogged, locationEnabled: false)
            handler(.failure(Ext.Error.inner("download url error.")))
            return nil
        }
        
        let downloadTask = DownloadTask(url: url, cacheUrl: cacheUrl, stamp: stamp, progress: progress, handler: handler)
        guard append(downloadTask) else {
            Ext.debug("Downloading... | \(url.absoluteString)", logEnabled: downloadLogged, locationEnabled: false)
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

private extension DownloadTask {
    
    func progressHandler(_ date: Date, bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let elapsed = date.timeIntervalSince(startTime)
        let progress = Double(totalBytesWritten)/Double(totalBytesExpectedToWrite)
        let speed = Double(totalBytesWritten) / elapsed / 1024
        //Ext.debug("Download start \(startTime) progress: \(progress) | speed: \(speed)", locationEnabled: false)
        self.progress?(progress, speed)
    }
    func successHandler(_ date: Date, session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let downloadUrlString = downloadTask.currentRequest?.url?.absoluteString ?? ""
        let elapsed = date.timeIntervalSince(startTime)
        guard let httpResponse = downloadTask.response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            let statusCode = (downloadTask.response as? HTTPURLResponse)?.statusCode ?? -110
            Ext.debug("Download failed. \(elapsed) | \(downloadUrlString) | statusCode != 200, \(statusCode)",
                      tag: .failure, logEnabled: NetworkManager.shared.downloadLogged, locationEnabled: false)
            self.handler(.failure(Ext.Error.inner("download failed \(statusCode)")))
            return
        }
        
        let url = cacheUrl ?? URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(location.lastPathComponent)
        guard FileManager.default.ext.save(location, to: url) else {
            Ext.debug("Download file save failed.",
                      tag: .error, logEnabled: NetworkManager.shared.downloadLogged, locationEnabled: false)
            self.handler(.failure(Ext.Error.inner("download file save failed.")))
            return
        }
        Ext.debug("Download succeeded. \(elapsed) | \(downloadUrlString)",
                  tag: .success, logEnabled: NetworkManager.shared.downloadLogged, locationEnabled: false)
        self.handler(.success(url))
    }
    func errorHandler(_ date: Date, session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let elapsed = date.timeIntervalSince(startTime)
        let statusCode = (task.response as? HTTPURLResponse)?.statusCode ?? -110
        Ext.debug("Download error. \(elapsed) | \(task.currentRequest?.url?.absoluteString ?? "") | \(statusCode)",
                  error: error, tag: .failure, logEnabled: NetworkManager.shared.downloadLogged, locationEnabled: false)
        self.handler(.failure(error ?? Ext.Error.inner("download error \(statusCode)")))
    }
    
}
