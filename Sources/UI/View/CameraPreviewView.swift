//
//  CameraPreviewView.swift
//  Ext
//
//  Created by naijoug on 2020/7/22.
//

import AVKit

open class CameraPreviewView: ExtView {
    
    private lazy var session: AVCaptureSession = {
        let session = AVCaptureSession()
        if let videoDevice = AVCaptureDevice.default(for: .video),
            let videoInput = try? AVCaptureDeviceInput(device: videoDevice) {
            session.addInput(videoInput)
        }
        return session
    }()
    
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    open override func setupUI() {
        super.setupUI()
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        layer.insertSublayer(previewLayer, at: 0)
        previewLayer.videoGravity = .resizeAspectFill
    }
    deinit {
        stopRunning()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        previewLayer.frame = self.bounds
    }
    
    public func startRunning() {
        guard !session.isRunning else { return }
        DispatchQueue.global().async {
            self.session.startRunning()
        }
    }
    public func stopRunning() {
        guard session.isRunning else { return }
        session.stopRunning()
    }
}
