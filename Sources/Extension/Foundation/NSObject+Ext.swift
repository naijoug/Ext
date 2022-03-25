//
//  NSObject+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/28.
//

import Foundation

public extension ExtWrapper where Base: NSObject {
    
    /**
     Reference:
        - https://stackoverflow.com/questions/24494784/get-class-name-of-object-as-string-in-swift
     */
    
    var typeName: String { String(describing: type(of: base)) }
    
    static var typeName: String { String(describing: Base.self) }
}

// MARK: - Associated Object

/**
 Reference:
    - https://nshipster.cn/associated-objects/
    - https://draveness.me/ao
    - https://www.desgard.com/objective-c/2016/07/29/Associated-Objects.html
    - https://blog.ficowshen.com/page/post/61
 
    [Swift Asscociated Object](https://github.com/inso-/SwiftAssociatedObject)
 */

public extension ExtWrapper where Base: NSObject {
    enum AssociationPolicy {
        case assign
        case copy
        case copyNonatomic
        case retain
        case retainNonatomic
        
        public var objcPolicy: objc_AssociationPolicy {
            switch self {
            case .assign:           return .OBJC_ASSOCIATION_ASSIGN
            case .copy:             return .OBJC_ASSOCIATION_COPY
            case .copyNonatomic:    return .OBJC_ASSOCIATION_COPY_NONATOMIC
            case .retain:           return .OBJC_ASSOCIATION_RETAIN
            case .retainNonatomic:  return .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            }
        }
    }
    
    func getAssociatedObject<T>(_ key: UnsafeRawPointer, valueType: T.Type) -> T? {
        objc_getAssociatedObject(base, key) as? T
    }
    func setAssociatedObject<T>(_ key: UnsafeRawPointer, value: T?, policy: AssociationPolicy) {
        objc_setAssociatedObject(base, key, value, policy.objcPolicy)
    }
}

// MARK: - Swizzling Method

extension ExtWrapper where Base: NSObject {

    /**
     Reference :
        - https://stackoverflow.com/questions/5339276/what-are-the-dangers-of-method-swizzling-in-objective-c
        - https://stackoverflow.com/questions/39562887/how-to-implement-method-swizzling-swift-3-0
        - https://nshipster.com/swift-objc-runtime/
    */
    
    
    public static func swizzlingClassMethod(_ cls: AnyClass,
                                            original originalSEL: Selector,
                                            swizzled swizzledSEL: Selector) {
        guard let originalMethod = class_getClassMethod(cls, originalSEL),
            let swizzledMethod = class_getClassMethod(cls, swizzledSEL) else {
                return
        }
        swizzlingMethod(cls,
                        originalSEL: originalSEL,
                        swizzledSEL: swizzledSEL,
                        originalMethod: originalMethod,
                        swizzledMethod: swizzledMethod)
    }
    
    public static func swizzlingInstanceMethod(_ cls: AnyClass,
                                               original originalSEL: Selector,
                                               swizzled swizzledSEL: Selector) {
        guard let originalMethod = class_getInstanceMethod(cls, originalSEL),
            let swizzledMethod = class_getInstanceMethod(cls, swizzledSEL) else {
                return
        }
        swizzlingMethod(cls,
                        originalSEL: originalSEL,
                        swizzledSEL: swizzledSEL,
                        originalMethod: originalMethod,
                        swizzledMethod: swizzledMethod)
    }
    
    private static func swizzlingMethod(_ cls: AnyClass,
                                        originalSEL: Selector,
                                        swizzledSEL: Selector,
                                        originalMethod: Method,
                                        swizzledMethod: Method) {
        let isAddSuccess = class_addMethod(cls,
                                           originalSEL,
                                           method_getImplementation(swizzledMethod),
                                           method_getTypeEncoding(swizzledMethod))
        guard isAddSuccess else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
            return
        }
        class_replaceMethod(cls,
                            swizzledSEL,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod))
    }

}
