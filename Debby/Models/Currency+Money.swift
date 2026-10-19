//
//  Currency+Money.swift
//  Debby
//
//  Created by Shox on 18/10/26.
//

import Foundation

nonisolated extension Currency {
    /// 1234.56 € → 123456. Rounds half away from zero (0.005 € → 1 cent).
    func minorUnits(from amount: Decimal) -> Int {
        var scaled = amount * pow(10, fractionDigits)
        var rounded = Decimal()
        NSDecimalRound(&rounded, &scaled, 0, .plain)
        return NSDecimalNumber(decimal: rounded).intValue
    }

    /// 123456 → 1234.56 €. Exact, no floating point involved.
    func amount(fromMinorUnits minorUnits: Int) -> Decimal {
        Decimal(minorUnits) / pow(10, fractionDigits)
    }
}
