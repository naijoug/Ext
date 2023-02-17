//
//  String+Size.swift
//  Ext
//
//  Created by naijoug on 2021/1/28.
//

import UIKit

// Reference: https://stackoverflow.com/questions/30450434/figure-out-size-of-uilabel-based-on-string-in-swift

public extension ExtWrapper where Base == String {
    
    func height(_ width: CGFloat, font: UIFont) -> CGFloat { ceil(boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude), font: font).height) }
    func width(_ height: CGFloat, font: UIFont) -> CGFloat { ceil(boundingRect(with: CGSize(width: .greatestFiniteMagnitude, height: height), font: font).width) }
    
    private func boundingRect(with size: CGSize, font: UIFont) -> CGRect {
        base.boundingRect(with: size,
                          options: .usesLineFragmentOrigin,
                          attributes: [NSAttributedString.Key.font: font],
                          context: nil)
    }
}

public extension ExtWrapper where Base == NSAttributedString {
    
    func size(height: CGFloat) -> CGSize { boundingRect(with: CGSize(width: .greatestFiniteMagnitude, height: height)).size }
    func size(width: CGFloat) -> CGSize { boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude)).size }
    
    func height(_ width: CGFloat) -> CGFloat { ceil(boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude)).height) }
    func width(_ height: CGFloat) -> CGFloat { ceil(boundingRect(with: CGSize(width: .greatestFiniteMagnitude, height: height)).width) }
    
    private func boundingRect(with size: CGSize) -> CGRect {
        base.boundingRect(with: size, options: .usesLineFragmentOrigin, context: nil)
    }
}

// MARK: - UIView

public extension ExtWrapper where Base == String {
    
    func widthFitTextField(_ height: CGFloat, font: UIFont) -> CGFloat {
        let textField = UITextField()
        textField.text = base
        textField.font = font
        return textField.ext.widthFit(height)
    }
    
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
}
public extension ExtWrapper where Base == NSAttributedString {
    
    func widthFitTextField(_ height: CGFloat) -> CGFloat {
        let field = UITextField()
        field.attributedText = base
        return field.ext.widthFit(height)
    }
    
    func heightFitLabel(_ width: CGFloat, numberOfLines: Int = 0) -> CGFloat {
        let label = UILabel()
        label.attributedText = base
        label.numberOfLines = numberOfLines
        return label.ext.heightFit(width)
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
