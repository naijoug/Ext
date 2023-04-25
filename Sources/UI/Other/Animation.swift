//
//  Animation.swift
//  Ext
//
//  Created by guojian on 2021/9/23.
//

import UIKit

public extension Ext {
    enum Animation {}
}

public extension Ext.Animation {
    
    /// 图片飞行动画
    static func fly(image: UIImage?, startView: UIView?, endView: UIView?, handler: Ext.ResultVoidHandler?) {
        guard let image = image else {
            handler?(.failure(Ext.Error.inner("fly image is nil.")))
            return
        }
        
        guard let view = UIWindow.ext.main,
            let startView = startView, let endView = endView,
            let startPoint = startView.superview?.convert(startView.center, to: view),
            let endPoint = endView.superview?.convert(endView.center, to: view) else {
            Ext.inner.ext.log("fly animation path error.")
            handler?(.failure(Ext.Error.inner("animation path error.")))
            return
        }
        Ext.inner.ext.log("\(startView) | \(endView)")
        Ext.inner.ext.log("animation start: \(startPoint) -> end: \(endPoint)")
        
        let animationImageView = UIImageView(image: image)
        view.addSubview(animationImageView)
        animationImageView.center = startPoint
        
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            Ext.inner.ext.log("fly animation completion.")
            animationImageView.removeFromSuperview()
            handler?(.success(()))
        }
        animationImageView.layer.add(flyAnimation(start: startPoint, end: endPoint), forKey: nil)
        CATransaction.commit()
    }
    private static func flyAnimation(start: CGPoint, end: CGPoint) -> CAAnimationGroup {
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = Float.pi
        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.toValue = 0.2
        let controlOffsetX: CGFloat = 100
        let controlOffsetY: CGFloat = 100
        let controlX = (start.x + end.x)/2 - controlOffsetX
        let controlY = (start.y + end.y)/2 - controlOffsetY
        
        let keyframe = CAKeyframeAnimation(keyPath: "position")
        let path = UIBezierPath()
        path.move(to: start)
        path.addQuadCurve(to: end, controlPoint: CGPoint(x: controlX, y: controlY))
        keyframe.path = path.cgPath
        keyframe.calculationMode = CAAnimationCalculationMode.paced
        keyframe.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        
        let groupAnimation = CAAnimationGroup()
        groupAnimation.duration = 1.0
        groupAnimation.fillMode = .forwards
        groupAnimation.isRemovedOnCompletion = false
        groupAnimation.animations = [rotation, scale, keyframe]
        return groupAnimation
    }
    
}
