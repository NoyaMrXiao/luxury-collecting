//
//  Extensions.swift
//  luxury-collecting
//
//  Created by ode-xiao on 2025/11/11.
//

import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Date Extensions
extension Date {
    func formatted(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: self)
    }
}

// MARK: - Double Extensions
extension Double {
    func formattedAsCurrency(locale: Locale = Locale(identifier: "zh_CN")) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        return formatter.string(from: NSNumber(value: self)) ?? "¥\(self)"
    }
}

// MARK: - View Extensions
extension View {
    func hideKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}

