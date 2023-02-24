//
//  UIViewController+Lifecycle.swift
//  Ext
//
//  Created by naijoug on 2022/3/24.
//

import UIKit

extension ExtWrapper where Base: UIViewController {
    
    /// Debug UIViewController Lifecycle
    static func lifecycle() {
        guard Ext.isDebug else { return }
        //Ext.inner.ext.log("♻️ UIViewController Lifecycle debugging")
        UIViewController.lifecycle()
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
            guard let self else { return }
            Ext.inner.ext.log("♻️ Deallocated: \(self.ext.typeName)")
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
    
    /// 是否为 UIKit 系统控制器
    private var isUIKit: Bool {
        let name = typeName
        let map = [ // 系统控制器表
            "UIInputWindowController": true,
            "UISystemKeyboardDockController": true,
            "_UIRemoteInputViewController": true,
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
        let name = typeName
        return name.hasPrefix("Doraemon") && name.hasSuffix("Controller")
    }
    
    /// 控制器是否显示生命周期日志
    private var lifecycleEnabled: Bool { !isUIKit && !isDoKit }
    
    func log(_ lifecycle: Lifecycle) {
        guard base.ext.lifecycleEnabled else { return }
        Ext.inner.ext.log("\(lifecycle.tag) \(lifecycle.title) \t | \(base.ext.typeName)")
    }
}
