//
//  AmountPartsTests.swift
//  DebbyTests
//
//  Created by Shox on 29/10/26.
//

import Testing
@testable import Debby

struct AmountPartsTests {
    @Test func splitsAWholeAmountWithASuffixSymbol() {
        let parts = AmountParts("67.500,00 ₽", fractionDigits: 2, decimalSeparator: ",")

        #expect(parts.head == "67.500")
        #expect(parts.fraction == ",00")
        #expect(parts.tail == " ₽")
        #expect(parts.isWhole)
        #expect(parts.compact == "67.500 ₽")
    }

    @Test func splitsAnAmountWithAPrefixSymbol() {
        let parts = AmountParts("$1,234.50", fractionDigits: 2, decimalSeparator: ".")

        #expect(parts.head == "$1,234")
        #expect(parts.fraction == ".50")
        #expect(parts.tail == "")
        #expect(!parts.isWhole)
        #expect(parts.compact == "$1,234.50")
    }

    @Test func keepsTheSignInTheHead() {
        let parts = AmountParts("−5,05 €", fractionDigits: 2, decimalSeparator: ",")

        #expect(parts.head == "−5")
        #expect(parts.fraction == ",05")
        #expect(parts.tail == " €")
    }

    @Test func aCurrencyWithoutDecimalsIsNeverSplit() {
        // The "." here is a thousands separator, not a decimal one.
        let parts = AmountParts("1.234 UZS", fractionDigits: 0, decimalSeparator: ",")

        #expect(parts.head == "1.234 UZS")
        #expect(parts.fraction == "")
        #expect(parts.compact == "1.234 UZS")
    }

    @Test func incompleteDigitsAreLeftAlone() {
        let parts = AmountParts("1,2", fractionDigits: 2, decimalSeparator: ",")

        #expect(parts.head == "1,2")
        #expect(parts.fraction == "")
    }
}
