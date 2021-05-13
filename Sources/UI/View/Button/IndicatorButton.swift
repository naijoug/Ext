//
//  IndicatorButton.swift
//  Ext
//
//  Created by naijoug on 2019/10/11.
//

import UIKit

/// 联网指示器按钮
open class IndicatorButton: UIButton {
    
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
    
    /// 是否正在
    open var isNetworking: Bool = false {
        didSet {
            isEnabled = !isNetworking
            /**
             UIButton's imageView property and hidden/alpha value:
             https://stackoverflow.com/questions/11673479/uibuttons-imageview-property-and-hidden-alpha-value
             */
            imageView?.layer.transform = isNetworking ? CATransform3DMakeScale(0, 0, 0) : CATransform3DIdentity
            titleLabel?.layer.transform = isNetworking ? CATransform3DMakeScale(0, 0, 0) : CATransform3DIdentity
            isNetworking ? indicatorView.startAnimating() : indicatorView.stopAnimating()
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
