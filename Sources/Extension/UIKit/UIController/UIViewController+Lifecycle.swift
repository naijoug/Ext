//
//  UIViewController+Lifecycle.swift
//  Ext
//
//  Created by naijoug on 2022/3/24.
//

import UIKit

public extension ExtWrapper where Base: UIViewController {
    
    /// 控制类名
    var className: String { "\(type(of: base))" }
    
    /// Debug UIViewController Lifecycle
    static func lifecycle() {
        guard Ext.isDebug else { return }
        //Ext.debug("UIViewController Lifecycle debugging", tag: .recycle, locationEnabled: false)
        UIViewController.lifecycle()
    }
}
private extension ExtWrapper where Base: UIViewController {
    /// 控制器生命周期
    enum Lifecycle {
        case viewDidLoad
        case viewWillAppear
        case viewDidAppear
        case viewWillDisappear
        case viewDidDisappear
        
        var tag: String {
            switch self {
            case .viewDidLoad:          return "🌞"
            case .viewWillAppear:       return "🌖"
            case .viewDidAppear:        return "🌕"
            case .viewWillDisappear:    return "🌒"
            case .viewDidDisappear:     return "🌑"
            }
        }
        var title: String {
            switch self {
            case .viewDidLoad:          return "viewDidLoad         "
            case .viewWillAppear:       return "viewWillAppear      "
            case .viewDidAppear:        return "viewDidAppear       "
            case .viewWillDisappear:    return "viewWillDisappear   "
            case .viewDidDisappear:     return "viewDidDisappear    "
            }
        }
    }
    
    func log(_ lifecycle: Lifecycle) {
        guard isValid else { return }
        Ext.debug("\(lifecycle.title) \t | \(className)", tag: .custom(lifecycle.tag), locationEnabled: false)
    }
}

// Reference: https://stackoverflow.com/questions/40647504/is-it-possible-to-swizzle-deinit-using-swift-if-yes-then-how-to-achieve-this

final class Deallocator {

    var closure: () -> Void

    init(_ closure: @escaping () -> Void) {
        self.closure = closure
    }

    deinit {
        closure()
    }
}

private extension UIViewController {
    
    static func lifecycle() {
        ext.swizzlingInstanceMethod(self, original: #selector(viewDidLoad), swizzled: #selector(lifecycle_viewDidLoad))
        ext.swizzlingInstanceMethod(self, original: #selector(viewWillAppear(_:)), swizzled: #selector(lifecycle_viewWillAppear(_:)))
        ext.swizzlingInstanceMethod(self, original: #selector(viewDidAppear(_:)), swizzled: #selector(lifecycle_viewDidAppear(_:)))
        ext.swizzlingInstanceMethod(self, original: #selector(viewWillDisappear(_:)), swizzled: #selector(lifecycle_viewWillDisappear(_:)))
        ext.swizzlingInstanceMethod(self, original: #selector(viewDidDisappear(_:)), swizzled: #selector(lifecycle_viewDidDisappear(_:)))
    }
    
    private static var deallocatorKey: UInt8 = 0
    @objc
    func lifecycle_viewDidLoad() {
        let deallocator = Deallocator { [weak self] in
            guard let `self` = self else { return }
            Ext.debug("Deallocated: \(self.ext.className)", tag: .recycle)
        }
        ext.setAssociatedObject(&Self.deallocatorKey, value: deallocator, policy: .retainNonatomic)
        
        lifecycle_viewDidLoad()
        ext.log(.viewDidLoad)
    }
    @objc
    func lifecycle_viewWillAppear(_ animated: Bool) {
        lifecycle_viewWillAppear(animated)
        ext.log(.viewWillAppear)
    }
    @objc
    func lifecycle_viewDidAppear(_ animated: Bool) {
        lifecycle_viewDidAppear(animated)
        ext.log(.viewDidAppear)
    }
    @objc
    func lifecycle_viewWillDisappear(_ animated: Bool) {
        lifecycle_viewWillDisappear(animated)
        ext.log(.viewWillDisappear)
    }
    @objc
    func lifecycle_viewDidDisappear(_ animated: Bool) {
        lifecycle_viewDidDisappear(animated)
        ext.log(.viewDidDisappear)
    }
}

private extension ExtWrapper where Base: UIViewController {
    /// 是否为 UIKit 系统控制器
    private var isUIKit: Bool {
        let name = className
        let map = [ // 系统控制器表
            "UIInputWindowController": true,
            "UIAlertController": true,
            "UINavigationController": true,
            "QLPreviewController": true,
            "QLRemotePreviewCollection": true,
            "QLRemoteAccessoryViewController": true
        ]
        return (map[name] ?? false) || (name.hasPrefix("UI") && name.hasSuffix("ViewController"))
    }
    /// 是否为 DoKit 控制器
    private var isDoKit: Bool {
        let name = className
        return name.hasPrefix("Doraemon") && name.hasSuffix("Controller")
    }
    
    private var isValid: Bool { !isUIKit && !isDoKit }
}
