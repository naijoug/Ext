//
//  DisableActionTextField.swift
//  Ext
//
//  Created by guojian on 2022/12/5.
//

import UIKit

open class DisableActionTextField: UITextField {
    public enum EditAction {
        case cut
        case copy
        case paste
        case select
        case selectAll
        case delete
    }
    
    public var disableActions: [EditAction] = [.cut, .copy, .paste, .select, .selectAll, .delete]
    
    open override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(UIResponderStandardEditActions.cut(_:)), disableActions.contains(EditAction.cut) {
            return false
        } else if action == #selector(UIResponderStandardEditActions.copy(_:)), disableActions.contains(EditAction.copy) {
            return false
        } else if action == #selector(UIResponderStandardEditActions.paste(_:)), disableActions.contains(EditAction.paste) {
            return false
        } else if action == #selector(UIResponderStandardEditActions.select(_:)), disableActions.contains(EditAction.select) {
            return false
        } else if action == #selector(UIResponderStandardEditActions.selectAll(_:)), disableActions.contains(EditAction.selectAll) {
            return false
        } else if action == #selector(UIResponderStandardEditActions.delete(_:)), disableActions.contains(EditAction.delete) {
            return false
        }
        return super.canPerformAction(action, withSender: sender)
    }
}
