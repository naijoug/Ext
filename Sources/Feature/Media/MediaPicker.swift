//
//  MediaPicker.swift
//  Ext
//
//  Created by guojian on 2022/8/8.
//

import UIKit
import MobileCoreServices

/// 系统媒体资源选择器
public struct MediaPicker {}

public extension MediaPicker {
    /// 媒体资源类型
    enum MediaType {
        case image
        case video
        case all
    }
    /// 媒体资源结果
    enum MediaResult {
        /// 选取图片
        case image(original: UIImage?, edited: UIImage?)
        /// 选取视频
        case video(url: URL?)
        /// 选取未知类型资源
        case unknown
        /// 取消
        case cancelled
    }
    
    /// 选取媒体资源
    /// - Parameters:
    ///   - from: 来源类型
    ///   - mediaType: 媒体类型
    ///   - editEnabled: 是否可编辑
    ///   - handler: 结果回调
    static func pick(from sourceType: UIImagePickerController.SourceType, mediaType: MediaPicker.MediaType, editEnabled: Bool = false, handler: @escaping Ext.DataHandler<MediaPicker.MediaResult>) {
        InnerMediaPicker.shared.pick(sourceType, mediaType: mediaType, editEnabled: editEnabled, handler: handler)
    }
}

private final class InnerMediaPicker: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    static let shared = InnerMediaPicker()
    
    private var handler: Ext.DataHandler<MediaPicker.MediaResult>?
    
    private var isPicking: Bool = false {
        didSet {
            Ext.inner.ext.log("\(oldValue) -> \(isPicking)")
        }
    }
    
    /**
     kUTTypeImage : "public.image"
     kUTTypeMovie : "public.movie"
     */
    private let imageMediaType = kUTTypeImage as String
    private let videoMediaType = kUTTypeMovie as String
    
    /// 选取媒体资源
    /// - Parameters:
    ///   - sourceType: 来源类型
    ///   - mediaType: 媒体类型
    ///   - editEnabled: 是否可编辑
    ///   - handler: 结果回调
    func pick(_ sourceType: UIImagePickerController.SourceType, mediaType: MediaPicker.MediaType, editEnabled: Bool = false, handler: @escaping Ext.DataHandler<MediaPicker.MediaResult>) {
        self.handler = handler
        Ext.inner.ext.log("availableMediaTypes: \(UIImagePickerController.availableMediaTypes(for: .photoLibrary) ?? [])")
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = editEnabled
        picker.sourceType = sourceType
        switch mediaType {
        case .image: () // 默认: 图片类型
        case .video:
            picker.mediaTypes = [videoMediaType]
        case .all:
            picker.mediaTypes = [imageMediaType, videoMediaType]
        }
        Ext.inner.ext.log("picker mediaType \(mediaType) => \(picker.mediaTypes)")
        UIApplication.ext.topViewController()?.present(picker, animated: true)
        isPicking = true
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        let mediaType = info[.mediaType] as? String
        Ext.inner.ext.log("picker finished mediaType: \(mediaType ?? "")")
        switch mediaType {
        case imageMediaType:
            let imageURL = info[.imageURL] as? URL
            let originalImage = info[.originalImage] as? UIImage
            let editedImage = info[.editedImage] as? UIImage
            Ext.inner.ext.log("picker image | imageURL: \(imageURL?.path ?? "") | original \(String(describing: originalImage)) | edited \(String(describing: editedImage))")
            handler?(.image(original: originalImage, edited: editedImage))
        case videoMediaType:
            let mediaURL = info[.mediaURL] as? URL
            Ext.inner.ext.log("picker video | mediaURL: \(mediaURL?.path ?? "")")
            handler?(.video(url: mediaURL))
        default:
            Ext.inner.ext.log("picker unknown mediaType.")
            handler?(.unknown)
        }
        picker.dismiss(animated: true)
        isPicking = false
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        handler?(.cancelled)
        picker.dismiss(animated: true)
        isPicking = false
    }
}
