//
//  AVAsset+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/26.
//

import AVFoundation

// - https://stackoverflow.com/questions/11090760/progress-bar-for-avassetexportsession

public extension ExtWrapper where Base == URL {
    
    /// 媒体资源时长
    var duration: TimeInterval { AVAsset(url: base).duration.seconds }
    
}

public extension ExtWrapper where Base == UIDevice {
    /**
     Reference:
        - https://support.apple.com/zh-cn/HT207022
        - https://www.jianshu.com/p/a8ec307000f2
     */
    
    /// 设备是否支持进行 HEVC 编码处理
    static let hevcEnabled: Bool = AVAssetExportSession.allExportPresets().contains(AVAssetExportPresetHEVCHighestQuality)
}

public extension ExtWrapper where Base == AVAsset {
    /// 资源 URL
    var url: URL? { (base as? AVURLAsset)?.url }
    
    /// 视频尺寸
    var videoSize: CGSize? {
        // Reference: https://stackoverflow.com/questions/10433774/avurlasset-getting-video-size
        guard let videoTrack = base.tracks(withMediaType: .video).first else { return nil }
        let size = videoTrack.naturalSize.applying(videoTrack.preferredTransform)
        //Ext.inner.ext.log("naturalSize: \(videoTrack.naturalSize) => \(size)")
        return CGSize(width: abs(size.width), height: abs(size.height))
    }
}

import AudioToolbox

public extension Ext {
    
    // Reference: https://stackoverflow.com/questions/35738133/ios-code-to-convert-m4a-to-wav
    
    /// 媒体资源转化为 Wav 音频文件
    /// - Parameters:
    ///   - sourceURL: 源文件
    ///   - outputURL: 输出的 Wav 音频文件
    static func convertToWav(sourceURL: URL, outputURL: URL) {
        Ext.inner.ext.log("convert to Wav start...")
        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            Ext.inner.ext.log("convert file not exist.")
            return
        }
        
        var error: OSStatus = noErr
        var destinationFile: ExtAudioFileRef?
        var sourceFile: ExtAudioFileRef?
        
        var srcFormat: AudioStreamBasicDescription = AudioStreamBasicDescription()
        var dstFormat: AudioStreamBasicDescription = AudioStreamBasicDescription()
        
        func log(_ message: String) {
            Ext.inner.ext.log("\(message) \(error == noErr ? "succeeded." : "failed. \(error.description)")", logEnabled: error != noErr)
        }
        
        ExtAudioFileOpenURL(sourceURL as CFURL, &sourceFile)
        guard let sourceFile = sourceFile else {
            Ext.inner.ext.log("audio file open failed")
            return
        }
        
        var thePropertySize: UInt32 = UInt32(MemoryLayout.stride(ofValue: srcFormat))

        ExtAudioFileGetProperty(sourceFile,
                                kExtAudioFileProperty_FileDataFormat,
                                &thePropertySize, &srcFormat)

        dstFormat.mSampleRate = 44100  //Set sample rate
        dstFormat.mFormatID = kAudioFormatLinearPCM
        dstFormat.mChannelsPerFrame = 1
        dstFormat.mBitsPerChannel = 16
        dstFormat.mBytesPerPacket = 2 * dstFormat.mChannelsPerFrame
        dstFormat.mBytesPerFrame = 2 * dstFormat.mChannelsPerFrame
        dstFormat.mFramesPerPacket = 1
        dstFormat.mFormatFlags = kLinearPCMFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger

        // Create destination file
        error = ExtAudioFileCreateWithURL(
            outputURL as CFURL,
            kAudioFileWAVEType,
            &dstFormat,
            nil,
            AudioFileFlags.eraseFile.rawValue,
            &destinationFile)
        guard let destinationFile = destinationFile else {
            Ext.inner.ext.log("destination file create failed. \(error.description)")
            return
        }
        log("① create audio file")

        error = ExtAudioFileSetProperty(sourceFile,
                                        kExtAudioFileProperty_ClientDataFormat,
                                        thePropertySize,
                                        &dstFormat)
        log("② set source file property")

        error = ExtAudioFileSetProperty(destinationFile,
                                        kExtAudioFileProperty_ClientDataFormat,
                                        thePropertySize,
                                        &dstFormat)
        log("③ set destination file property")

        let bufferByteSize: UInt32 = 32768
        var srcBuffer = [UInt8](repeating: 0, count: 32768)
        let uint8Pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: srcBuffer.count)
        uint8Pointer.initialize(from: &srcBuffer, count: srcBuffer.count)
        var sourceFrameOffset: ULONG = 0

        while true {
            var fillBufList = AudioBufferList(
                mNumberBuffers: 1,
                mBuffers: AudioBuffer(mNumberChannels: 2, mDataByteSize: UInt32(srcBuffer.count), mData: uint8Pointer)
            )
            var numFrames: UInt32 = 0

            if dstFormat.mBytesPerFrame > 0 {
                numFrames = bufferByteSize / dstFormat.mBytesPerFrame
            }

            error = ExtAudioFileRead(sourceFile, &numFrames, &fillBufList)
            log("④ read source file - \(numFrames)")

            if numFrames == 0 {
                error = noErr
                break
            }

            sourceFrameOffset += numFrames
            error = ExtAudioFileWrite(destinationFile, numFrames, &fillBufList)
            log("⑤ write destination file - \(numFrames) | \(sourceFrameOffset)")
        }

        error = ExtAudioFileDispose(destinationFile)
        log("⑥ dispose destination")
        error = ExtAudioFileDispose(sourceFile)
        log("⑦ dispose source")
        Ext.inner.ext.log("convert to Wav end.")
    }
    
    /// 转化为 MP4
    static func convertToMP4(sourceURL: URL,
                             outputURL: URL = FileManager.ext.file(for: .temp, fileName: .timestamp, fileExtension: "mp4"),
                             handler: @escaping Ext.ResultDataHandler<URL>) {
        let presetName = UIDevice.ext.hevcEnabled ? AVAssetExportPresetHEVCHighestQuality : AVAssetExportPresetHighestQuality
        guard let export = AVAssetExportSession(asset: AVAsset(url: sourceURL), presetName: presetName) else {
            handler(.failure(Ext.Error.inner("export session init failed.")))
            return
        }
        export.outputURL = outputURL
        export.outputFileType = .mp4
        FileManager.default.ext.remove(outputURL)
        export.exportAsynchronously {
            DispatchQueue.main.async {
                switch export.status {
                case .completed:
                    handler(.success(outputURL))
                case .cancelled:
                    handler(.failure(Ext.Error.inner("convert to MP4 canccelled.")))
                default:
                    handler(.failure(export.error ?? Ext.Error.inner("convert to MP4 failed")))
                }
            }
        }
    }
}

public extension ExtWrapper where Base: AVAsset {
    
    /// 裁剪资源
    /// - Parameters:
    ///   - range: 裁剪范围
    ///   - outputURL: 输出 url
    func crop(_ range: CMTimeRange, outputURL: URL, handler: @escaping Ext.ResultDataHandler<URL>) {
        let presetName = UIDevice.ext.hevcEnabled ? AVAssetExportPresetHEVCHighestQuality : AVAssetExportPreset1920x1080
        guard let export = AVAssetExportSession(asset: base, presetName: presetName) else {
            handler(.failure(Ext.Error.inner("export session init failed.")))
            return
        }
        export.outputURL = outputURL
        export.outputFileType = .mp4
        export.timeRange = range
        FileManager.default.ext.remove(outputURL)
        export.exportAsynchronously {
            DispatchQueue.main.async {
                switch export.status {
                case .completed:
                    //Ext.inner.ext.log("crop video completed.")
                    handler(.success(outputURL))
                case .cancelled:
                    handler(.failure(Ext.Error.inner("crop video cancelled")))
                default:
                    handler(.failure(export.error ?? Ext.Error.inner("crop video failed")))
                }
            }
        }
    }
}

// MARK: - Image

public extension Ext {
    typealias ImageFrame = (image: UIImage, time: CMTime)
    typealias ExportImageHandler = Ext.ResultDataHandler<[ImageFrame]>
}

public extension ExtWrapper where Base: AVAsset {
    
    /// 导出指定帧数图片
    /// - Parameters:
    ///   - size: 图片尺寸
    ///   - frames: 导出图片帧数
    ///   - handler: 导出结果
    func exportImages(_ size: CGSize, frames: Int, handler: @escaping Ext.ExportImageHandler) {
        let times = (0..<frames).map {
            CMTime(seconds: base.duration.seconds * TimeInterval($0)/TimeInterval(frames), preferredTimescale: base.duration.timescale)
        }
        exportImages(size, times: times, handler: handler)
    }
    
    /// 按指定时间帧间隔导出图片
    /// - Parameters:
    ///   - size: 图片尺寸
    ///   - frameInterval: 导出图片帧间隔 (单位: 秒)
    ///   - handler: 导出结果
    func exportImages(_ size: CGSize, frameInterval: TimeInterval, handler: @escaping Ext.ExportImageHandler) {
        let durationT = base.duration.seconds // 总时长
        let frameInterval = min(frameInterval, durationT)
        guard frameInterval > 0 else {
            handler(.failure(Ext.Error.inner("frame interval \(frameInterval) error.")))
            return
        }
        // 计算间隔时间
        let fullFrames = Int(durationT/frameInterval) // 完整帧数
        let remainderT = durationT - TimeInterval(fullFrames)*frameInterval // 剩余时长
        let lastW = size.width * CGFloat(remainderT/frameInterval)  // 最后一帧图片宽度
        //Ext.log("总时长: \(seconds) | 完整帧数: \(fullFrames) | 剩余时长: \(remainderT) | 最后一帧图片宽度\(lastW)")
        let times = stride(from: 0, to: durationT, by: frameInterval).map {
            CMTime(seconds: $0, preferredTimescale: base.duration.timescale)
        }
        exportImages(size, times: times) { result in
            switch result {
            case .failure(let error): handler(.failure(error))
            case .success(var frames):
                // 对最后一帧图片进行裁剪
                if lastW > 0, frames.count > 0 {
                    let last = frames.removeLast()
                    if let image = last.image.ext.clip(in: CGRect(x: 0, y: 0, width: lastW, height: size.height)) {
                        frames.append((image, last.time))
                    }
                }
                handler(.success(frames))
            }
        }
    }
    /// 导出多张图片(异步)
    ///
    /// - Parameters:
    ///   - size: 图片最大尺寸
    ///   - times: 导出图片时间点
    ///   - handler: 导出结果
    func exportImages(_ size: CGSize, times: [CMTime], handler: @escaping Ext.ExportImageHandler) {
        func handleResult(_ result: Result<[Ext.ImageFrame], Swift.Error>) {
            DispatchQueue.main.async {
                handler(result)
            }
        }
        
        guard !times.isEmpty else {
            handler(.success([]))
            return
        }
        let generator = AVAssetImageGenerator(asset: base)
        generator.requestedTimeToleranceAfter    = .zero
        generator.requestedTimeToleranceBefore   = .zero
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = size
        
        //Ext.inner.ext.log("times: \(times)")
        var frames = [Ext.ImageFrame]()
        var count = 0
        generator.generateCGImagesAsynchronously(forTimes: times.map { NSValue(time: $0) }) { (requestedTime, cgImage, actualTime, result, error) in
            switch result {
            case .succeeded:
                if let cgImage = cgImage {
                    frames.append((UIImage(cgImage: cgImage), actualTime))
                }
            case .cancelled:
                Ext.inner.ext.log("export \(requestedTime) image cancelled.", error: error)
                handleResult(.failure(Ext.Error.inner("export \(requestedTime) image cancelled.")))
            default:
                Ext.inner.ext.log("export \(requestedTime) image failed.", error: error)
                handleResult(.failure(error ?? Ext.Error.inner("export \(requestedTime) image failed.")))
            }
            
            count += 1
            guard count == times.count else { return } // 全部导出完成
            handleResult(.success(frames))
        }
    }
    
    /// 导出一帧图片(同步)
    ///
    /// - Parameters:
    ///   - size: 图片最大尺寸
    ///   - time: 导出图片时间点
    func exportImage(_ size: CGSize, time: CMTime) -> Ext.ImageFrame? {
        let generator = AVAssetImageGenerator(asset: base)
        generator.requestedTimeToleranceAfter    = .zero
        generator.requestedTimeToleranceBefore   = .zero
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = size
        
        do {
            var actualTime = CMTime(value: 0, timescale: 0) // actual time for the image
            let cgImage = try generator.copyCGImage(at: time, actualTime: &actualTime)
            return (UIImage(cgImage: cgImage), actualTime)
        } catch {
            Ext.inner.ext.log("image generate failed.", error: error)
            return nil
        }
    }
}
