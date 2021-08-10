//
//  IndicatorButton.swift
//  Ext
//
//  Created by naijoug on 2019/10/11.
//

import UIKit

/// 指示器协议
public protocol Indicatable: AnyObject {
    /// 指示器状态
    var isIndicating: Bool { get set }
}

/// 联网指示器按钮
open class IndicatorButton: UIButton, Indicatable {
    
    /// 指示器视图
    open lazy var indicatorView: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView(style: .gray)
        addSubview(indicatorView)
        indicatorView.style = .gray
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        indicatorView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        indicatorView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        return indicatorView
    }()
    
    /// 指示器状态
    public var isIndicating: Bool = false {
        didSet {
            isEnabled = !isIndicating
            /**
             UIButton's imageView property and hidden/alpha value:
             https://stackoverflow.com/questions/11673479/uibuttons-imageview-property-and-hidden-alpha-value
             */
            imageView?.layer.transform = isIndicating ? CATransform3DMakeScale(0, 0, 0) : CATransform3DIdentity
            titleLabel?.layer.transform = isIndicating ? CATransform3DMakeScale(0, 0, 0) : CATransform3DIdentity
            isIndicating ? indicatorView.startAnimating() : indicatorView.stopAnimating()
        }
    }
    
    /// 是否正在
    open var isNetworking: Bool = false {
        didSet {
            isIndicating = isNetworking
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        bringSubviewToFront(indicatorView)
    }
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    @objc
    open func setupUI() {}
}
