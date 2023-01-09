//
//  Media.swift
//  Ext
//
//  Created by guojian on 2023/1/9.
//

import Foundation
import CoreMedia

/// 视频处理协议
public protocol VideoProcessable: AnyObject {
    /// 处理视频帧
    func processFrame(_ frame: CVPixelBuffer) -> CVPixelBuffer
}
