//
//  DisableActionTextField.swift
//  Ext
//
//  Created by guojian on 2022/12/5.
//

import UIKit

public enum EditAction {
    case cut
    case copy
    case paste
    case select
    case selectAll
    case delete
}

open class DisableActionTextField: UITextField {
    public var disableActions: [EditAction] = [.cut, .copy, .paste, .select, .selectAll, .delete]
    
    open override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(UIResponderStandardEditActions.cut(_:)), disableActions.contains(.cut) {
            return false
        } else if action == #selector(UIResponderStandardEditActions.copy(_:)), disableActions.contains(.copy) {
            return false
        } else if action == #selector(UIResponderStandardEditActions.paste(_:)), disableActions.contains(.paste) {
            return false
        } else if action == #selector(UIResponderStandardEditActions.select(_:)), disableActions.contains(.select) {
            return false
        } else if action == #selector(UIResponderStandardEditActions.selectAll(_:)), disableActions.contains(.selectAll) {
            return false
        } else if action == #selector(UIResponderStandardEditActions.delete(_:)), disableActions.contains(.delete) {
            return false
        }
        return super.canPerformAction(action, withSender: sender)
    }
}

open class DisableActionTextView: UITextView {
    public var disableActions: [EditAction] = [.cut, .copy, .paste, .select, .selectAll, .delete]
    
    open override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(UIResponderStandardEditActions.cut(_:)), disableActions.contains(.cut) {
            return false
        } else if action == #selector(UIResponderStandardEditActions.copy(_:)), disableActions.contains(.copy) {
            return false
        } else if action == #selector(UIResponderStandardEditActions.paste(_:)), disableActions.contains(.paste) {
            return false
        } else if action == #selector(UIResponderStandardEditActions.select(_:)), disableActions.contains(.select) {
            return false
        } else if action == #selector(UIResponderStandardEditActions.selectAll(_:)), disableActions.contains(.selectAll) {
            return false
        } else if action == #selector(UIResponderStandardEditActions.delete(_:)), disableActions.contains(.delete) {
            return false
        }
        return super.canPerformAction(action, withSender: sender)
    }
}
