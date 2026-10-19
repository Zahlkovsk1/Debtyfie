//
//  Currency+Format.swift
//  Debby
//
//  Created by Shox on 19/10/26.
//

import Foundation

nonisolated extension Currency {
    /// "1.234,56 €": grouping, decimal separator, and symbol position
    /// all follow the locale. Currencies are never converted.
    func formatted(_ amount: Decimal, locale: Locale = .current) -> String {
        amount.formatted(.currency(code: code).locale(locale))
    }

    /// Same thing, straight from the whole number stored in the database.
    func formatted(minorUnits: Int, locale: Locale = .current) -> String {
        formatted(amount(fromMinorUnits: minorUnits), locale: locale)
    }
}
