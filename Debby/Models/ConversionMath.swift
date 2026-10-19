//
//  ConversionMath.swift
//  Debby
//
//  Created by Shox on 19/10/26.
//

import Foundation

nonisolated enum ConversionMath {
    /// Rates keep up to 6 decimals.
    static let rateDigits = 6

    /// 10.000 × 0,92 → 9.200, rounded to what the second currency can hold.
    static func counterAmount(amount: Decimal, rate: Decimal, in currency: Currency) -> Decimal {
        rounded(amount * rate, scale: currency.fractionDigits)
    }

    /// 9.200 ÷ 10.000 → 0,92. Nil when there is nothing to divide by.
    static func rate(amount: Decimal, counterAmount: Decimal) -> Decimal? {
        guard amount > 0 else { return nil }
        return rounded(counterAmount / amount, scale: rateDigits)
    }

    /// Text for an input field: no thousands separators, no trailing zeros,
    /// and the decimal separator of the locale.
    static func text(_ value: Decimal, maxDecimals: Int, locale: Locale = .current) -> String {
        value.formatted(
            .number
                .precision(.fractionLength(0...maxDecimals))
                .grouping(.never)
                .locale(locale)
        )
    }

    private static func rounded(_ value: Decimal, scale: Int) -> Decimal {
        var input = value
        var output = Decimal()
        NSDecimalRound(&output, &input, scale, .plain)
        return output
    }
}
