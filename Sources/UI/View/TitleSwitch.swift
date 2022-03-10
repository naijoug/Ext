//
//  TitleSwitch.swift
//  Ext
//
//  Created by naijoug on 2021/9/7.
//

import UIKit

public protocol TitleSwitchDelegate: AnyObject {
    func titleSwitch(_ titleSwitch: TitleSwitch, didSwitch isOn: Bool)
}

/// 带文字的 Switch 控件
public class TitleSwitch: ExtControl {
    public weak var delegate: TitleSwitchDelegate?
    
    /// 文字
    private lazy var titleLabel: UILabel = {
        ext.add(UILabel()).setup {
            $0.font = titleFont
        }
    }()
    /// 开关纽扣
    private lazy var toggle: UIView = {
        ext.add(UIView(), backgroundColor: .white).setup {
            $0.isUserInteractionEnabled = false
            $0.ext.roundCorner(radius: toggleWH/2)
        }
    }()
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        toggle.ext.dropShadow()
    }
    public override func setupUI() {
        super.setupUI()
        ext.roundCorner(radius: viewH/2)
        addTarget(self, action: #selector(tapAction), for: .touchUpInside)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleWidthConstraint = titleLabel.widthAnchor.constraint(equalToConstant: 50)
        NSLayoutConstraint.activate([
            titleWidthConstraint,
            titleLabel.heightAnchor.constraint(equalToConstant: viewH),
            titleLabel.topAnchor.constraint(equalTo: self.topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: viewH/2),
            titleLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -viewH/2)
        ])
        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggleOnConstraint = toggle.centerXAnchor.constraint(equalTo: titleLabel.trailingAnchor)
        toggleOffConstraint = toggle.centerXAnchor.constraint(equalTo: titleLabel.leadingAnchor)
        NSLayoutConstraint.activate([
            toggle.widthAnchor.constraint(equalToConstant: toggleWH),
            toggle.heightAnchor.constraint(equalToConstant: toggleWH),
            toggle.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            isOn ? toggleOnConstraint : toggleOffConstraint
        ])
        
        reloadUI()
    }
    
    /// 当前状态
    public private(set) var isOn: Bool = false
    
    private var onConfig = Config("", color: .systemGreen, titleColor: .white)
    private var offConfig = Config("", color: .white, titleColor: .lightGray)
    
    private let viewH: CGFloat = 30
    private let toggleWH: CGFloat = 30 - 2
    private var titleFont: UIFont = UIFont.systemFont(ofSize: 13)
    
    private var titleWidthConstraint = NSLayoutConstraint()
    private var toggleOnConstraint = NSLayoutConstraint()
    private var toggleOffConstraint = NSLayoutConstraint()
}
private extension TitleSwitch {
    
    /// 刷新 UI
    private func reloadUI() {
        titleLabel.textAlignment = isOn ? .left : .right
        titleLabel.textColor = isOn ? onConfig.titleColor : offConfig.titleColor
        titleLabel.text = isOn ? onConfig.title : offConfig.title
        backgroundColor = isOn ? onConfig.color : offConfig.color
        
        ext.borderLine(1, color: isOn ? onConfig.color : offConfig.titleColor)
        toggle.ext.borderLine(1, color: isOn ? onConfig.color : offConfig.titleColor)
    }
    
    @objc
    private func tapAction() {
        setOn(!isOn, animated: true)
        delegate?.titleSwitch(self, didSwitch: isOn)
    }
}

public extension TitleSwitch {
    /// 配置
    struct Config {
        public let title: String
        public let color: UIColor
        public let titleColor: UIColor
        
        public init(_ title: String, color: UIColor, titleColor: UIColor) {
            self.title = title
            self.color = color
            self.titleColor = titleColor
        }
    }
    
    
    /// 配置 switch
    /// - Parameters:
    ///   - on: on 状态配置
    ///   - off: off 状态配置
    func config(on: Config, off: Config) {
        self.onConfig = on
        self.offConfig = off
        
        let onW: CGFloat = on.title.ext.width(viewH, font: titleFont)
        let offW: CGFloat = off.title.ext.width(viewH, font: titleFont)
        let titleW = max(onW, offW) + 5 + viewH/2
        Ext.debug("onW: \(onW) : offW: \(offW) | titleW: \(titleW)")
        titleWidthConstraint.constant = titleW
        layoutIfNeeded()
        
        reloadUI()
    }
    
    
    /// 切换状态
    /// - Parameters:
    ///   - on: 是否打开状态
    ///   - animated: 是否有动画效果
    func setOn(_ on: Bool, animated: Bool = false) {
        guard isOn != on else { return }
        self.isOn = on
        
        func doSwitch() {
            toggleOnConstraint.isActive = isOn
            toggleOffConstraint.isActive = !isOn
            layoutIfNeeded()
            
            self.reloadUI()
        }
        guard animated else {
            doSwitch()
            return
        }
        UIView.animate(withDuration: 0.3) {
            doSwitch()
        }
    }
    
}
