//
//  MoneyFormatTests.swift
//  DebbyTests
//
//  Created by Shox on 19/10/26.
//

import Testing
import Foundation
@testable import Debby

struct MoneyFormatTests {
    let german = Locale(identifier: "de_DE")
    let american = Locale(identifier: "en_US")

    @Test func euroInGermanStyle() {
        let text = Currency.eur.formatted(Decimal(string: "1234.56")!, locale: german)
        #expect(text.contains("1.234,56"))
        #expect(text.contains("€"))
    }

    @Test func dollarInAmericanStyle() {
        let text = Currency.usd.formatted(Decimal(string: "1234.56")!, locale: american)
        #expect(text.contains("1,234.56"))
        #expect(text.contains("$"))
    }

    @Test func formatsStraightFromMinorUnits() {
        // 920000 cents = 9.200,00 €
        let text = Currency.eur.formatted(minorUnits: 920_000, locale: german)
        #expect(text.contains("9.200,00"))
    }

    @Test func negativeKeepsItsSign() {
        let text = Currency.eur.formatted(minorUnits: -920_000, locale: german)
        #expect(text.contains("9.200,00"))
        #expect(text.contains("-") || text.contains("−"))
    }

    @Test func yenHasNoDecimals() {
        let text = Currency(code: "JPY").formatted(minorUnits: 5_000, locale: american)
        #expect(text.contains("5,000"))
        #expect(!text.contains("."))
    }
}
