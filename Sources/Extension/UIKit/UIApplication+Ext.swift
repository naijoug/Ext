//
//  UIApplication+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/28.
//

import UIKit

public extension ExtWrapper where Base == UIApplication {
    /// 当前版本号
    static var version: String { (Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String) ?? "0" }
    /// 构建版本号
    static var build: String { (Bundle.main.infoDictionary!["CFBundleVersion"] as? String) ?? "" }
}

@available(iOSApplicationExtension, unavailable)
public extension ExtWrapper where Base == UIApplication {
    
    /// 状态栏高
    var statusBarHeight: CGFloat { base.statusBarFrame.size.height }
    /// 安全区域 Insets
    var safeAreaInsets: UIEdgeInsets { mainWindow?.safeAreaInsets ?? UIEdgeInsets(top: statusBarHeight, left: 0, bottom: 0, right: 0) }
    
    /// 安全的底部间隙 safeAreaInsets.bottom > 0 ? safeAreaInsets.bottom : bottom
    func safeBottom(_ bottom: CGFloat) -> CGFloat { safeAreaInsets.bottom > 0 ? safeAreaInsets.bottom : bottom }
    
    /// 顶部高度 = (安全区域顶部偏移 + 导航栏高度)
    var topHeight: CGFloat  { safeAreaInsets.top + 44 }
    /// 底部高度 = (工具栏高度 + 安全区域底部偏移)
    var bottomHeight: CGFloat { 49 + safeAreaInsets.bottom }
    
    /**
     系统键盘尺寸
     宽度 = 屏幕宽度
     高度 = (键盘高度 + 安全区域偏移)
        216 : 没有工具栏
        260 : 有工具栏 (216 + 44)
        Reference:
            - https://developer.apple.com/library/archive/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/KeyboardManagement/KeyboardManagement.html
    */
    var keyboardSize: CGSize { CGSize(width: UIScreen.main.ext.screenWidth, height: 216 + safeAreaInsets.bottom) }
}

@available(iOSApplicationExtension, unavailable)
public extension ExtWrapper where Base == UIApplication {
    
    /// 主窗口
    var mainWindow: UIWindow? {
        /** Reference :
           - https://stackoverflow.com/questions/57134259/how-to-resolve-keywindow-was-deprecated-in-ios-13-0
        */
        if #available(iOS 13.0, *),
            let window = base.connectedScenes
            .filter({$0.activationState == .foregroundActive})
            .map({$0 as? UIWindowScene})
            .compactMap({$0})
            .first?.windows
            .filter({$0.isKeyWindow}).first {
            return window
        }
        return UIApplication.shared.windows.filter { $0.isKeyWindow }.first ?? UIApplication.shared.keyWindow
    }
    
    /// 返回顶层控制器
    ///
    /// - Parameter controller: 基础控制器
    /// - Returns: 可视控制器
    func topViewController(_ controller: UIViewController? = UIApplication.shared.ext.mainWindow?.rootViewController) -> UIViewController? {
        /** Reference:
            - https://stackoverflow.com/questions/26667009/get-top-most-uiviewcontroller
        */
        if let tabBar = controller as? UITabBarController {
            return topViewController(tabBar.selectedViewController)
        }
        if let nav = controller as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        if let presented = controller?.presentedViewController {
            return topViewController(presented)
        }
        print("\(String(describing: controller))")
        return controller
    }
}

@available(iOSApplicationExtension, unavailable)
public extension ExtWrapper where Base == UIApplication {
    
    /**
     Reference:
        - https://stackoverflow.com/questions/22115319/how-to-open-photo-app-from-uiviewcontroller
     */
    
    /// 系统功能页面
    enum SystemFeature {
        case album
        case setting
    }
    
    /// 打开系统功能页面
    /// - Parameter feature: 功能页面
    func open(_ feature: SystemFeature) {
        var url: URL?
        switch feature {
        case .album:
            url = URL(string:"photos-redirect://")
        case .setting:
            url = URL(string: UIApplication.openSettingsURLString)
        }
        guard let url = url else { return }
        base.open(url, options: [:], completionHandler: nil)
    }
    
    /// 退出 App
    func exitApp() {
        /** Reference:
         - https://stackoverflow.com/questions/3097244/exit-application-in-ios-4-0
         - https://stackoverflow.com/questions/26511014/how-to-exit-app-and-return-to-home-screen-in-ios-8-using-swift-programming
         */
        UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { (timer) in
            exit(0)
        }
    }
    
    /// 清理 LaunchScreen 缓存
    func clearLaunchScreeenCache() {
        /** Reference:
           - https://stackoverflow.com/questions/33002829/ios-keeping-old-launch-screen-and-app-icon-after-update
        */
        do {
            let path1 = NSHomeDirectory() + "/Library/Caches/Snapshots"
            if FileManager.default.fileExists(atPath: path1) {
                try FileManager.default.removeItem(atPath: path1)
            }
            let path2 = NSHomeDirectory() + "/Library/SplashBoard"
            if FileManager.default.fileExists(atPath: path2) {
                try FileManager.default.removeItem(atPath: path2)
            }
        } catch {
            Ext.debug("Failed to clear LaunchScreen cache", error: error, tag: .fix, locationEnabled: false)
        }
    }
}
