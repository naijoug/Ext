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
        //Ext.debug("naturalSize: \(videoTrack.naturalSize) => \(size)")
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
        Ext.debug("convert to Wav start...", tag: .begin, logEnabled: Ext.logEnabled, locationEnabled: false)
        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            Ext.debug("convert file not exist.", logEnabled: Ext.logEnabled, locationEnabled: false)
            return
        }
        
        var error: OSStatus = noErr
        var destinationFile: ExtAudioFileRef?
        var sourceFile: ExtAudioFileRef?
        
        var srcFormat: AudioStreamBasicDescription = AudioStreamBasicDescription()
        var dstFormat: AudioStreamBasicDescription = AudioStreamBasicDescription()
        
        func log(_ message: String) {
            Ext.debug("\(message) \(error == noErr ? "succeeded." : "failed. \(error.description)")", logEnabled: error != noErr, locationEnabled: false)
        }
        
        ExtAudioFileOpenURL(sourceURL as CFURL, &sourceFile)
        guard let sourceFile = sourceFile else {
            Ext.debug("audio file open failed", tag: .error)
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
            Ext.debug("destination file create failed. \(error.description)", logEnabled: Ext.logEnabled, locationEnabled: false)
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
        Ext.debug("convert to Wav end.", tag: .end, logEnabled: Ext.logEnabled, locationEnabled: false)
    }
    
}
