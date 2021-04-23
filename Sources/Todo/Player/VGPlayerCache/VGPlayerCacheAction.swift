//
//  VGPlayerCacheAction.swift
//  Pods
//
//  Created by Vein on 2017/6/27.
//
//

import Foundation

public enum VGPlayerCacheActionType: Int {
    case local
    case remote
}

public struct VGPlayerCacheAction: Hashable, CustomStringConvertible {
    public var type: VGPlayerCacheActionType
    public var range: NSRange
    
    public var description: String {
        return "type: \(type)  range:\(range)"
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(range)
    }
    
    public static func ==(lhs: VGPlayerCacheAction, rhs: VGPlayerCacheAction) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    init(type: VGPlayerCacheActionType, range: NSRange) {
        self.type = type
        self.range = range
    }
    
}
