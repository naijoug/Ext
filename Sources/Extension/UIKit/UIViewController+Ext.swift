//
//  UIViewController+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/28.
//

import UIKit

// MARK: - Storyboard

public extension ExtWrapper where Base: UIViewController {
    
    /// 从指定 Storyboard 创建控制器
    ///
    /// - Parameter sbName: Storyboard 名称
    /// - Parameter bundle: Storyboard 所在 Bundle
    /// - Returns: 当前控制器类型实例
    static func instantiateFromStoryboard(sbName: String, bundle: Bundle? = nil) -> Base {
        func instanceFromStoryboard<T>(sbName: String) -> T where T: UIViewController {
            if let vc = UIStoryboard(name: sbName, bundle: bundle).instantiateViewController(withIdentifier: "\(Base.self)") as? T {
                return vc
            }
            fatalError("Load storyboard controller failure \(self)")
        }
        return instanceFromStoryboard(sbName: sbName)
    }
    
}

// MARK: -

public extension ExtWrapper where Base: UIViewController {
    
    /// 控制器视图是否加载
    var isViewLoaded: Bool { base.viewIfLoaded != nil }
    
    /// 控制器是否可见
    var isVisible: Bool {
        // Refrence: https://stackoverflow.com/questions/2777438/how-to-tell-if-uiviewcontrollers-view-is-visible
        return base.viewIfLoaded?.window != nil
    }
    
    /// 导航栏返回按钮标题
    func backTitle(_ title: String = "") {
        base.navigationItem.backBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: nil, action: nil)
    }
    
    /// 是否使用导航栏大标题
    func largeTitle(_ enabled: Bool) {
        base.navigationController?.navigationBar.prefersLargeTitles = enabled
        base.navigationItem.largeTitleDisplayMode = enabled ? .always : .never
    }
}

// MARK: - Child Controller

public extension ExtWrapper where Base: UIViewController {
    
    // Reference: https://www.swiftbysundell.com/articles/using-child-view-controllers-as-plugins-in-swift/
    
    /// 添加子控制器
    func add<T: UIViewController>(_ child: T) -> T {
        base.addChild(child)
        base.view.addSubview(child.view)
        child.didMove(toParent: base)
        return child
    }
    
    /// 从父控制器移除
    func remove() {
        guard base.parent != nil else { return }
        base.didMove(toParent: nil)
        base.view.removeFromSuperview()
        base.removeFromParent()
    }
}

// MARK: - Navigation

public extension ExtWrapper where Base: UINavigationController {
    
    /**
     导航控制器的根控制器
     Reference:
        - https://stackoverflow.com/questions/1792858/how-do-i-get-the-rootviewcontroller-from-a-pushed-controller
     */
    var rootViewController: UIViewController? { base.viewControllers.first }
    
    /// 删除导航 stack 控制器
    ///
    /// - Parameter cls: 控制器类型
    func removeController(_ cls: AnyClass) {
        removeControllers([cls])
    }
    
    /// 删除导航 stack 多个控制器
    ///
    /// - Parameter clss: 控制器类型列表
    func removeControllers(_ clss: [AnyClass]) {
        var vcs = base.viewControllers
        let current = vcs.removeLast()
        for (index, vc) in vcs.enumerated().reversed() {
            for cls in clss {
                if vc.isMember(of: cls) {
                    vcs.remove(at: index)
                }
            }
        }
        vcs.append(current)
        base.setViewControllers(vcs, animated: false)
    }
    
    /// 打印当前导航堆栈
    func logControllers() {
        for vc in base.viewControllers.reversed() {
            print("\(vc)")
        }
    }
}

// MARK: - Lifecycle

public extension ExtWrapper where Base: UIViewController {
    
    /// 控制类名
    var className: String { "\(type(of: base))" }
    
    /// Debug UIViewController Lifecycle
    static func debug() {
        guard Ext.isDebug else { return }
        //Ext.debug("UIViewController Lifecycle debugging", tag: .recycle, locationEnabled: false)
        UIViewController.swizzle()
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

private var associatedObjectAddr = ""

private extension UIViewController {
    
    static func swizzle() {
        ext.swizzlingInstanceMethod(self, original: #selector(viewDidLoad), swizzled: #selector(swizzled_viewDidLoad))
        ext.swizzlingInstanceMethod(self, original: #selector(viewWillAppear(_:)), swizzled: #selector(swizzled_viewWillAppear(_:)))
        ext.swizzlingInstanceMethod(self, original: #selector(viewDidAppear(_:)), swizzled: #selector(swizzled_viewDidAppear(_:)))
        ext.swizzlingInstanceMethod(self, original: #selector(viewWillDisappear(_:)), swizzled: #selector(swizzled_viewWillDisappear(_:)))
        ext.swizzlingInstanceMethod(self, original: #selector(viewDidDisappear(_:)), swizzled: #selector(swizzled_viewDidDisappear(_:)))
    }
    
    @objc
    func swizzled_viewDidLoad() {
        let deallocator = Deallocator { [weak self] in
            guard let `self` = self else { return }
            Ext.debug("Deallocated: \(self.ext.className)", tag: .recycle)
        }
        objc_setAssociatedObject(self, &associatedObjectAddr, deallocator, .OBJC_ASSOCIATION_RETAIN)
        
        swizzled_viewDidLoad()
        ext.log(.viewDidLoad)
    }
    @objc
    func swizzled_viewWillAppear(_ animated: Bool) {
        swizzled_viewWillAppear(animated)
        ext.log(.viewWillAppear)
    }
    @objc
    func swizzled_viewDidAppear(_ animated: Bool) {
        swizzled_viewDidAppear(animated)
        ext.log(.viewDidAppear)
    }
    @objc
    func swizzled_viewWillDisappear(_ animated: Bool) {
        swizzled_viewWillDisappear(animated)
        ext.log(.viewWillDisappear)
    }
    @objc
    func swizzled_viewDidDisappear(_ animated: Bool) {
        swizzled_viewDidDisappear(animated)
        ext.log(.viewDidDisappear)
    }
}
