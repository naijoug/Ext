//
//  RecordButton.swift
//  Ext
//
//  Created by guojian on 2020/6/16.
//

import UIKit

public protocol RecordButtonDelegate: AnyObject {
    func recordButton(_ button: RecordButton, didAction action: RecordButton.Action)
}

/// 录制按钮
public class RecordButton: ExtView {
    public enum Action {
        case tap(_ isRecording: Bool)       // 点击状态
        case longPress(_ isRecording: Bool) // 长按状态
    }
    public weak var delegate: RecordButtonDelegate?
    
// MARK: - Status
    
    /// 是否开始录制
    public var isRecording: Bool = false {
        didSet {
            isRecording ? startRecording() : stopRecording()
        }
    }
    
    /// 是否支持长按手势
    public var longPressEnabled: Bool = true
    
    /// 是否可用
    public var isEnabled: Bool = true {
        didSet {
            let color = isEnabled ? (isRecording ? recordColor : normalColor) : disabledColor
            circleBorder.borderColor = color.cgColor
            innerCircle.backgroundColor = color
        }
    }
    
// MARK: - UI
    
    /// 定时器
    private var timer: Timer?
    
    private var normalColor: UIColor = .systemBlue
    private var recordColor: UIColor = .systemRed
    private var disabledColor: UIColor = .systemGray
    
    private var circleBorder: CALayer!
    private var innerCircle: UIView!
    
    private lazy var iconImageView: UIImageView = {
        let imageView = ext.add(UIImageView())
        imageView.contentMode = .center
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: self.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
        return imageView
    }()
    
    public override func setupUI() {
        super.setupUI()
        
        setupGestures()
        
        backgroundColor = UIColor.clear
        
        circleBorder = CALayer()
        layer.insertSublayer(circleBorder, at: 0)
        circleBorder.borderWidth = 1.0
        circleBorder.borderColor = normalColor.cgColor
        circleBorder.backgroundColor = UIColor.clear.cgColor
        circleBorder.bounds = bounds
        circleBorder.cornerRadius = bounds.width / 2
        circleBorder.position = CGPoint(x: bounds.midX, y: bounds.midY)
        circleBorder.isHidden = true
        
        innerCircle = UIView()
        addSubview(innerCircle)
        innerCircle.clipsToBounds = true
        innerCircle.backgroundColor = normalColor
        innerCircle.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.width)
        innerCircle.center = CGPoint(x: bounds.midX, y: bounds.midY)
        innerCircle.layer.cornerRadius = bounds.width / 2
    }
}

public extension RecordButton {
    
    /// 设置颜色
    func config(normal normalColor: UIColor, record recordColor: UIColor, disabled disabledColor: UIColor) {
        self.normalColor = normalColor
        self.recordColor = recordColor
        self.disabledColor = disabledColor
        
        circleBorder.borderColor = normalColor.cgColor
        innerCircle.backgroundColor = normalColor
    }
    /// 设置 icon 图片
    func config(icon image: UIImage?) {
        iconImageView.image = image
    }
}

// MARK: - Record

private extension RecordButton {
    
    /// 开始录制
    func startRecording() {
        self.iconImageView.alpha = 0
        UIView.animate(withDuration: 0.6, delay: 0.0, options: .curveEaseOut, animations: {
            self.innerCircle.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
            self.innerCircle.layer.cornerRadius = 8.0
            self.innerCircle.backgroundColor = self.recordColor
            
            self.circleBorder.borderColor = self.recordColor.cgColor
            self.circleBorder.setAffineTransform(CGAffineTransform(scaleX: 0.8, y: 0.8))
            self.circleBorder.borderWidth = 2
            self.circleBorder.isHidden = false
        }, completion: nil)
    }
    /// 停止录制
    func stopRecording() {
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut, animations: {
            self.innerCircle.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            self.innerCircle.layer.cornerRadius = self.innerCircle.frame.size.width / 2
            self.innerCircle.backgroundColor = self.normalColor
            
            self.circleBorder.borderColor = self.normalColor.cgColor
            self.circleBorder.setAffineTransform(CGAffineTransform(scaleX: 1.0, y: 1.0))
            self.circleBorder.borderWidth = 1
            self.circleBorder.isHidden = true
            
            self.iconImageView.alpha = 1
        }, completion: nil)
    }
}

// MARK: - Gesture

private extension RecordButton {
    /// 添加手势
    func setupGestures() {
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap(_:))))
        addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:))))
    }
    /// 点击手势
    @objc
    func tap(_ gesture: UITapGestureRecognizer) {
        guard isEnabled, gesture.state == .ended else { return }
        isRecording = !isRecording
        delegate?.recordButton(self, didAction: .tap(isRecording))
    }
    /// 长按手势
    @objc
    func longPress(_ gesture: UILongPressGestureRecognizer) {
        guard isEnabled, longPressEnabled else { return }
        
        switch gesture.state {
        case .began:
            isRecording = true
            delegate?.recordButton(self, didAction: .longPress(true))
        case .ended:
            guard isRecording else { return }
            isRecording = false
            delegate?.recordButton(self, didAction: .longPress(false))
        default: break
        }
    }
}
