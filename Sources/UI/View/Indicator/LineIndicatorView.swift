//
//  LineIndicatorView.swift
//  Ext
//
//  Created by guojian on 2021/6/3.
//

import UIKit

/// 指示器视图协议
public protocol IndicatorViewProtocol {
    func startAnimating()
    func stopAnimating()
}

extension UIActivityIndicatorView: IndicatorViewProtocol {}

/// 线条指示器
public class LineIndicatorView: ExtView, IndicatorViewProtocol {
    
    /// 指示器动画标识
    private var isAnimating = false
    
    private var gradientLayer: CAGradientLayer!
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        gradientLayer.bounds = self.bounds
        //Ext.log("line gradinet layout isAnimating \(isAnimating)")
    }
    public override func setupUI() {
        super.setupUI()
        
        gradientLayer = CAGradientLayer()
        layer.addSublayer(gradientLayer)
        gradientLayer.anchorPoint = .zero
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        var colors = [CGColor]()
        for i in stride(from: 0.0, to: 1.0, by: 0.1) {
            colors.append(UIColor.white.withAlphaComponent(CGFloat(i)).cgColor)
        }
        gradientLayer.colors = colors
    }
    
    private func shiftColors(_ colors: [CGColor]) -> [CGColor]? {
        guard !colors.isEmpty else { return nil }
        var newColors: [CGColor] = colors
        let last = newColors.removeLast()
        newColors.insert(last, at: 0)
        return newColors
    }
    
    private func performAnimation() {
        guard let fromColors = gradientLayer.colors as? [CGColor],
              let toColors = shiftColors(fromColors) else { return }
        gradientLayer.colors = toColors
        // color animation
        let animation = CABasicAnimation(keyPath: "colors")
        animation.fromValue = fromColors
        animation.toValue = toColors
        animation.duration = 0.1
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = true
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            guard self.isAnimating else { return }
            self.performAnimation()
        }
        layer.add(animation, forKey: "animateGradient")
        CATransaction.commit()
    }
    
    public func startAnimating() {
        self.isHidden = false
        guard !isAnimating else { return }
        self.isAnimating = true
        self.performAnimation()
    }
    public func stopAnimating() {
        self.isHidden = true
        guard isAnimating else { return }
        self.isAnimating = false
    }
}
