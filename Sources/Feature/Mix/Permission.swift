//
//  Permission.swift
//  Ext
//
//  Created by naijoug on 2022/5/11.
//

import Foundation

public extension Ext {
    /// 权限类型
    enum Permission {
        /// 通知权限
        case notification
        /// 相册权限
        case album
        /// 相机权限
        case camera
        /// 麦克风权限
        case microphone
        /// 语音识别权限
        case speech
    }
}
/// 授权协议
private protocol Authorized {
    /// 是否已授权
    var isAuthorized: Bool { get }
}
public extension Ext.Permission {
    
    /// 权限授权 (如果用户已经授权过，直接返回状态)
    /// - Parameter handler: 是否授权成功
    func authorize(_ handler: Ext.DataHandler<Bool>?) {
        switch self {
        case .notification:
            Self.notification { status in
                handler?(status.isAuthorized)
            }
        case .album:
            Self.album { status in
                handler?(status.isAuthorized)
            }
        case .camera:
            Self.camera { status in
                handler?(status.isAuthorized)
            }
        case .microphone:
            Self.microphone { status in
                handler?(status.isAuthorized)
            }
        case .speech:
            Self.speech { status in
                handler?(status.isAuthorized)
            }
        }
    }
    
    /// 是否授权
    var isAuthorized: Bool {
        switch self {
        case .notification: return Self.notificationStatus?.isAuthorized ?? false
        case .album:        return Self.albumStatus.isAuthorized
        case .camera:       return Self.cameraStatus.isAuthorized
        case .microphone:   return Self.microphoneStatus.isAuthorized
        case .speech:       return Self.speechStatus.isAuthorized
        }
    }
    
    /// 校验多个权限是否都授权
    static func isAuthorized(_ permissions: [Self]) -> Bool {
        !permissions.contains(where: { !$0.isAuthorized })
    }
}

// MARK: - Notification

import UserNotifications

extension UNAuthorizationStatus: Authorized {
    var isAuthorized: Bool {
        switch self {
        case .authorized: return true
        default: return false
        }
    }
}
extension Ext.Permission {
    /// 通知权限状态
    public static var notificationStatus: UNAuthorizationStatus? {
        var notificationSettings: UNNotificationSettings?
        let semasphore = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            UNUserNotificationCenter.current().getNotificationSettings { setttings in
                notificationSettings = setttings
                semasphore.signal()
            }
        }
        semasphore.wait()
        return notificationSettings?.authorizationStatus
    }
    
    /// 通知授权
    public static func notification(handler: Ext.DataHandler<UNAuthorizationStatus>?) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let status = settings.authorizationStatus
            switch status {
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .sound, .alert]) { (authorized, _) in
                    DispatchQueue.main.async {
                        handler?(authorized ? .authorized : .denied)
                    }
                }
            default:
                DispatchQueue.main.async {
                    handler?(status)
                }
            }
        }
    }
}

// MARK: - Photos

import Photos

extension PHAuthorizationStatus: Authorized {
    var isAuthorized: Bool {
        switch self {
        case .authorized, .limited: return true
        default: return false
        }
    }
}
extension Ext.Permission {
    private static var albumStatus: PHAuthorizationStatus {
        if #available(iOS 14, *) {
            return PHPhotoLibrary.authorizationStatus(for: .readWrite)
        } else {
            return PHPhotoLibrary.authorizationStatus()
        }
    }
    /// 相册授权
    public static func album(_ handler: Ext.DataHandler<PHAuthorizationStatus>?) {
        let status = albumStatus
        switch status {
        case .notDetermined:
            if #available(iOS 14, *) {
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                    DispatchQueue.main.sync {
                        handler?(status)
                    }
                }
            } else {
                PHPhotoLibrary.requestAuthorization { status in
                    DispatchQueue.main.async {
                        handler?(status)
                    }
                }
            }
        default:
            handler?(status)
        }
    }
}

// MARK: - Media

import AVFoundation

extension AVAuthorizationStatus: Authorized {
    var isAuthorized: Bool {
        switch self {
        case .authorized: return true
        default: return false
        }
    }
}
extension Ext.Permission {
    private static var cameraStatus: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }
    /// 相机 📷 授权
    static func camera(_ handler: Ext.DataHandler<AVAuthorizationStatus>?) {
        let status = cameraStatus
        switch status {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { authorized in
                DispatchQueue.main.async {
                    handler?(authorized ? .authorized : .denied)
                }
            }
        default: handler?(status)
        }
    }
    
    private static var microphoneStatus: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .audio)
    }
    /// 麦克风 🎤 授权
    static func microphone(_ handler: Ext.DataHandler<AVAuthorizationStatus>?) {
        /**
            Reference : https://developer.apple.com/documentation/avfoundation/avcapturedevice/1624584-requestaccess
            AVCaptureDevice.authorizationStatus(for: .audio) 等效于 AVAudioSession.sharedInstance().requestRecordPermission
         */
        let status = microphoneStatus
        switch status {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { authorized in
                DispatchQueue.main.async {
                    handler?(authorized ? .authorized : .denied)
                }
            }
        default: handler?(status)
        }
    }
}

// MARK: - Speech

import Speech

extension SFSpeechRecognizerAuthorizationStatus: Authorized {
    var isAuthorized: Bool {
        switch self {
        case .authorized: return true
        default: return false
        }
    }
}
extension Ext.Permission {
    private static var speechStatus: SFSpeechRecognizerAuthorizationStatus {
        SFSpeechRecognizer.authorizationStatus()
    }
    /// 语音识别
    public static func speech(_ handler: Ext.DataHandler<SFSpeechRecognizerAuthorizationStatus>?) {
        let status = speechStatus
        switch status {
        case .notDetermined:
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.main.async {
                    handler?(status)
                }
            }
        default: handler?(status)
        }
    }
}
