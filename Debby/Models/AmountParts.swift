//
//  AmountParts.swift
//  Debby
//
//  Created by Shox on 29/10/26.
//

import Foundation

/// A formatted amount cut into the part to show big and the part to show small.
/// "−67.500,00 ₽" becomes head "−67.500", fraction ",00", tail " ₽".
struct AmountParts: Equatable {
    /// Sign, currency prefix and the whole part.
    let head: String
    /// The decimal separator and the digits after it. Empty if the currency has none.
    let fraction: String
    /// Whatever follows the digits, such as " ₽".
    let tail: String
    /// True when the fraction digits are all zeros.
    let isWhole: Bool

    init(
        _ formatted: String,
        fractionDigits: Int,
        decimalSeparator: String = Locale.current.decimalSeparator ?? "."
    ) {
        // Start from "not split" and only change it if the text really has a fraction.
        var head = formatted
        var fraction = ""
        var tail = ""
        var isWhole = true

        if fractionDigits > 0,
           let separator = formatted.range(of: decimalSeparator, options: .backwards) {
            let afterSeparator = formatted[separator.upperBound...]
            let digits = afterSeparator.prefix(fractionDigits)

            if digits.count == fractionDigits, digits.allSatisfy(\.isNumber) {
                head = String(formatted[..<separator.lowerBound])
                fraction = decimalSeparator + String(digits)
                tail = String(afterSeparator.dropFirst(fractionDigits))
                isWhole = digits.allSatisfy { $0 == "0" }
            }
        }

        self.head = head
        self.fraction = fraction
        self.tail = tail
        self.isWhole = isWhole
    }

    /// The amount without ",00" when it is a whole number: "67.500 ₽".
    var compact: String {
        isWhole ? head + tail : head + fraction + tail
    }
}
