//
//  AssociatedObject.swift
//  Ext
//
//  Created by guojian on 2022/2/28.
//

import Foundation

public extension Ext {
    enum AssociationPolicy {
        case assign
        case copy
        case copyNonatomic
        case retain
        case retainNonatomic
    }
    
    static func getAssociatedObject<T>(_ object: AnyObject, key: UnsafeRawPointer) -> T? {
        objc_getAssociatedObject(object, key) as? T
    }
    static func setAssociatedObject<T>(_ object: AnyObject, key: UnsafeRawPointer, value: T, policy: AssociationPolicy) {
        objc_setAssociatedObject(object, key, value, policy.objcPolicy)
    }
}

private extension Ext.AssociationPolicy {
    var objcPolicy: objc_AssociationPolicy {
        switch self {
        case .assign:           return .OBJC_ASSOCIATION_ASSIGN
        case .copy:             return .OBJC_ASSOCIATION_COPY
        case .copyNonatomic:    return .OBJC_ASSOCIATION_COPY_NONATOMIC
        case .retain:           return .OBJC_ASSOCIATION_RETAIN
        case .retainNonatomic:  return .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        }
    }
}
