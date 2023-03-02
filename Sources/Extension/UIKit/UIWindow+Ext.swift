//
//  UIWindow+Ext.swift
//  Ext
//
//  Created by guojian on 2023/3/2.
//

import Foundation

@available(iOSApplicationExtension, unavailable)
public extension ExtWrapper where Base == UIWindow {
    
    /** Reference :
     - https://stackoverflow.com/questions/57134259/how-to-resolve-keywindow-was-deprecated-in-ios-13-0
     */
    
    /// 主窗口
    static var main: UIWindow? {
        if #available(iOS 13.0, *),
           let window = UIApplication.shared.ext.windowScenes
                            .first(where: { $0.windows.contains(where: { $0.isKeyWindow }) })?.windows
                            .first(where: { $0.isKeyWindow }) {
            return window
        }
        return UIApplication.shared.windows.filter { $0.isKeyWindow }.first ?? UIApplication.shared.keyWindow
    }
}
