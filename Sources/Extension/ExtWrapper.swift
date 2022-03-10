//
//  ExtWrapper.swift
//  Ext
//
//  Created by naijoug on 2021/1/26.
//

import Foundation

/**
 Reference:
    - https://github.com/ReactiveX/RxSwift/blob/main/RxSwift/Reactive.swift
    - https://kaushalelsewhere.medium.com/better-way-to-manage-swift-extensions-in-ios-project-78dc34221bc8
 */

public struct ExtWrapper<Base> {
    public let base: Base
    
    public init(_ base: Base) { self.base = base }
}

public protocol ExtCompatible {
    associatedtype CompatibleType
    
    static var ext: ExtWrapper<CompatibleType>.Type { get set }
    
    var ext: ExtWrapper<CompatibleType> { get set }
}

// swiftlint:disable unused_setter_value
public extension ExtCompatible {
    static var ext: ExtWrapper<Self>.Type {
        get { return ExtWrapper<Self>.self }
        set { }
    }
    var ext: ExtWrapper<Self> {
        get { return ExtWrapper(self) }
        set { }
    }
}
extension NSObject: ExtCompatible { }
