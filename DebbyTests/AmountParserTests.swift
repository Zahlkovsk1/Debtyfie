//
//  AmountParserTests.swift
//  DebbyTests
//
//  Created by Shox on 19/10/26.
//

import Testing
import Foundation
@testable import Debby

struct AmountParserTests {
    @Test func readsWholeNumbersAndDecimals() {
        #expect(AmountParser.parse("1500") == 1500)
        #expect(AmountParser.parse("12,50") == Decimal(string: "12.5"))
        #expect(AmountParser.parse("12.50") == Decimal(string: "12.5"))
        #expect(AmountParser.parse(".5") == Decimal(string: "0.5"))
    }

    @Test func ignoresSpaces() {
        #expect(AmountParser.parse("1 500") == 1500)
    }

    @Test func refusesAmbiguousOrBrokenInput() {
        #expect(AmountParser.parse("1.234,56") == nil)
        #expect(AmountParser.parse("12abc") == nil)
        #expect(AmountParser.parse("") == nil)
        #expect(AmountParser.parse(".") == nil)
        #expect(AmountParser.parse(",") == nil)
        #expect(AmountParser.parse("-5") == nil)
    }

    @Test func cutsExtraDecimals() {
        #expect(AmountParser.limitingDecimals("12,567", to: 2) == "12,56")
        #expect(AmountParser.limitingDecimals("12,5", to: 2) == "12,5")
        #expect(AmountParser.limitingDecimals("12,", to: 2) == "12,")
        #expect(AmountParser.limitingDecimals("1234", to: 2) == "1234")
    }

    @Test func currenciesWithoutDecimalsDropThem() {
        #expect(AmountParser.limitingDecimals("12,5", to: 0) == "12")
        #expect(AmountParser.limitingDecimals("12,", to: 0) == "12")
    }
}
