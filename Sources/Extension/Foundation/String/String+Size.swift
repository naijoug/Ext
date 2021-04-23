//
//  String+Size.swift
//  Ext
//
//  Created by naijoug on 2021/1/28.
//

import UIKit

// Reference: https://stackoverflow.com/questions/30450434/figure-out-size-of-uilabel-based-on-string-in-swift

public extension ExtWrapper where Base == String {
    
    func height(_ width: CGFloat, font: UIFont) -> CGFloat {
        let size = CGSize(width: width, height: .greatestFiniteMagnitude)
        let rect = base.boundingRect(with: size,
                                     options: .usesLineFragmentOrigin,
                                     attributes: [NSAttributedString.Key.font: font],
                                     context: nil)
        return ceil(rect.height) + 4
    }
    func width(_ height: CGFloat, font: UIFont) -> CGFloat {
        let size = CGSize(width: .greatestFiniteMagnitude, height: height)
        let rect = base.boundingRect(with: size,
                                     options: .usesLineFragmentOrigin,
                                     attributes: [NSAttributedString.Key.font: font],
                                     context: nil)
        return ceil(rect.width)
    }
}

public extension ExtWrapper where Base == NSAttributedString {
    func height(_ width: CGFloat) -> CGFloat {
        let size = CGSize(width: width, height: .greatestFiniteMagnitude)
        let rect = base.boundingRect(with: size, options: .usesLineFragmentOrigin, context: nil)
        return ceil(rect.height) + 4
    }
    func width(_ height: CGFloat) -> CGFloat {
        let size = CGSize(width: .greatestFiniteMagnitude, height: height)
        let rect = base.boundingRect(with: size, options: .usesLineFragmentOrigin, context: nil)
        return ceil(rect.width)
    }
}

// MARK: - UIView

public extension ExtWrapper where Base == String {
    
    func heightFitLabel(_ width: CGFloat, font: UIFont, numberOfLines: Int = 0) -> CGFloat {
        let label = UILabel()
        label.text = base
        label.font = font
        label.numberOfLines = numberOfLines
        return label.ext.heightFit(width)
    }
    
    func heightFitTextView(_ width: CGFloat, font: UIFont) -> CGFloat {
        let textView = UITextView()
        textView.text = base
        textView.font = font
        return textView.ext.heightFit(width)
    }
    
    func widthFitTextField(_ height: CGFloat, font: UIFont) -> CGFloat {
        let textField = UITextField()
        textField.text = base
        textField.font = font
        return textField.ext.widthFit(height)
    }
}
public extension ExtWrapper where Base == NSAttributedString {
    
    func widthFitTextField(_ height: CGFloat) -> CGFloat {
        let field = UITextField()
        field.attributedText = base
        return field.ext.widthFit(height)
    }
    
    func heightFitTextView(_ width: CGFloat) -> CGFloat {
        let textView = UITextView()
        textView.attributedText = base
        return textView.ext.heightFit(width)
    }
}

public extension ExtWrapper where Base: UIView {
    func widthFit(_ height: CGFloat) -> CGFloat {
        return ceil(base.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: height)).width)
    }
    func heightFit(_ width: CGFloat) -> CGFloat {
        return ceil(base.sizeThatFits(CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)).height)
    }
}
