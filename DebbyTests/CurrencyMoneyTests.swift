//
//  CurrencyMoneyTests.swift
//  DebbyTests
//
//  Created by Shox on 18/10/26.
//

import Testing
import Foundation
@testable import Debby

struct CurrencyMoneyTests {
    @Test func euroToCents() {
        #expect(Currency.eur.minorUnits(from: Decimal(string: "1234.56")!) == 123456)
    }

    @Test func yenHasNoDecimals() {
        #expect(Currency(code: "JPY").minorUnits(from: 1500) == 1500)
    }

    @Test func halfCentRoundsUp() {
        #expect(Currency.eur.minorUnits(from: Decimal(string: "0.005")!) == 1)
    }

    @Test func roundTripKeepsEveryCent() {
        let amount = Decimal(string: "10000.01")!
        let stored = Currency.usd.minorUnits(from: amount)
        #expect(stored == 1000001)
        #expect(Currency.usd.amount(fromMinorUnits: stored) == amount)
    }

    @Test func tenCentsPlusTwentyCentsIsThirtyCents() {
        // With Double, 0.1 + 0.2 = 0.30000000000000004
        let ten = Currency.eur.minorUnits(from: Decimal(string: "0.10")!)
        let twenty = Currency.eur.minorUnits(from: Decimal(string: "0.20")!)
        #expect(ten + twenty == 30)
    }
}
