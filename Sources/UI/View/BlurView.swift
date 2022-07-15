//
//  BlurView.swift
//  Ext
//
//  Created by guojian on 2022/7/15.
//

import UIKit

/// 模糊视图
public class BlurView: ExtView {
    
    private let style: UIBlurEffect.Style
    public init(_ style: UIBlurEffect.Style) {
        self.style = style
        
        super.init(frame: .zero)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    public override func setupUI() {
        super.setupUI()
        
        let blurView = ext.add(UIVisualEffectView(effect: UIBlurEffect(style: style)))
        blurView.ext.constraintToEdges(self)
        let vibrancyView = blurView.contentView.ext.add(UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: UIBlurEffect(style: style))))
        vibrancyView.ext.constraintToEdges(blurView.contentView)
    }
}
