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
