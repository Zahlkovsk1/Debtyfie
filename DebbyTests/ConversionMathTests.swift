//
//  ConversionMathTests.swift
//  DebbyTests
//
//  Created by Shox on 19/10/26.
//

import Testing
import Foundation
@testable import Debby

struct ConversionMathTests {
    @Test func dollarsToEuros() {
        let euros = ConversionMath.counterAmount(
            amount: 10_000, rate: Decimal(string: "0.92")!, in: .eur
        )
        #expect(euros == 9_200)
    }

    @Test func roundsToTheSecondCurrencysCents() {
        // 100 × 0,92155 = 92,155 → 92,16
        let euros = ConversionMath.counterAmount(
            amount: 100, rate: Decimal(string: "0.92155")!, in: .eur
        )
        #expect(euros == Decimal(string: "92.16"))
    }

    @Test func yenHasNoDecimals() {
        let yen = ConversionMath.counterAmount(
            amount: 1, rate: Decimal(string: "150.55")!, in: Currency(code: "JPY")
        )
        #expect(yen == 151)
    }

    @Test func rateFromAmounts() {
        #expect(ConversionMath.rate(amount: 10_000, counterAmount: 9_200) == Decimal(string: "0.92"))
    }

    @Test func rateKeepsSixDecimals() {
        #expect(ConversionMath.rate(amount: 3, counterAmount: 1) == Decimal(string: "0.333333"))
    }

    @Test func noRateWithoutAnAmount() {
        #expect(ConversionMath.rate(amount: 0, counterAmount: 100) == nil)
    }

    @Test func fieldTextHasNoTrailingZeros() {
        let us = Locale(identifier: "en_US")
        let de = Locale(identifier: "de_DE")
        #expect(ConversionMath.text(9_200, maxDecimals: 2, locale: us) == "9200")
        #expect(ConversionMath.text(Decimal(string: "12.5")!, maxDecimals: 2, locale: us) == "12.5")
        #expect(ConversionMath.text(Decimal(string: "0.92")!, maxDecimals: 6, locale: de) == "0,92")
        #expect(ConversionMath.text(Decimal(string: "0.333333")!, maxDecimals: 6, locale: us) == "0.333333")
    }
}
