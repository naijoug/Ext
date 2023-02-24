//
//  ImagePreviewView.swift
//  Ext
//
//  Created by naijoug on 2022/5/10.
//

import UIKit
import Photos

/// 图片预览视图
public class ImagePreviewView: ExtView {
    
    private var scrollView: UIScrollView!
    public private(set) var imageView: UIImageView!
    
    public override func setupUI() {
        super.setupUI()
        backgroundColor = .black
        
        scrollView  = ext.add(UIScrollView())
        imageView   = scrollView.ext.add(UIImageView())
        
        scrollView.bouncesZoom = true
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        scrollView.delegate = self
        scrollView.isMultipleTouchEnabled = true
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        self.imageView.addGestureRecognizer(doubleTap)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: self.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        imageView.frame.size = self.bounds.size
    }
    
    @objc
    private func doubleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        
        Ext.inner.ext.log("min: \(scrollView.minimumZoomScale) | max: \(scrollView.maximumZoomScale) | scale: \(scrollView.zoomScale)")
        guard scrollView.zoomScale == scrollView.minimumZoomScale else {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
            return
        }
        let zoomScale = scrollView.maximumZoomScale
        guard zoomScale > 0 else { return }
        let point = gesture.location(in: self.imageView)
        let size = scrollView.bounds.size
        let w = size.width / zoomScale
        let h = size.height / zoomScale
        let x = point.x - w / 2.0
        let y = point.y - h / 2.0
        scrollView.zoom(to: CGRect(x: x, y: y, width: w, height: h), animated: true)
    }
}
extension ImagePreviewView: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let contentSize = scrollView.contentSize
        let size = scrollView.frame.size
        imageView.center = CGPoint(
            x: contentSize.width > size.width ? contentSize.width/2 : scrollView.center.x,
            y: contentSize.height > size.height ? contentSize.height/2 : scrollView.center.y
        )
    }
}
