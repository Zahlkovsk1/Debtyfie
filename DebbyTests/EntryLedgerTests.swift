//
//  EntryLedgerTests.swift
//  DebbyTests
//
//  Created by Shox on 18/10/26.
//

import Testing
import Foundation
@testable import Debby

@MainActor
struct EntryLedgerTests {
    private let rate092 = Decimal(string: "0.92")!

    /// Dad: client hands over 10.000 $, you will repay in euros at 0,92
    private func dollarsInEuros() -> Entry {
        Entry(direction: .received, amount: 10_000, currency: .usd,
              conversion: Conversion(currency: .eur, amount: 9_200, rate: rate092))
    }

    @Test func dollarsInMeansYouOweEuros() {
        let entry = dollarsInEuros()
        #expect(entry.ledgerCurrency == .eur)
        #expect(entry.ledgerMinorUnits == -920_000)   // you owe him 9.200,00 €
        #expect(entry.currency == .usd)               // the cash that moved is dollars
        #expect(entry.amountMinor == 1_000_000)
    }

    @Test func payingTheEurosOutSettlesIt() {
        let paid = Entry(direction: .gave, amount: 9_200, currency: .eur)
        let received = dollarsInEuros()
        #expect(paid.ledgerCurrency == received.ledgerCurrency)
        #expect(paid.ledgerMinorUnits + received.ledgerMinorUnits == 0)
    }

    @Test func plainEntryUsesItsOwnCurrency() {
        let sale = Entry(direction: .gave, amount: 1_000, currency: .usd)
        #expect(sale.ledgerCurrency == .usd)
        #expect(sale.ledgerMinorUnits == 100_000)
    }

    @Test func rateAndAmountsComeBackExactly() {
        let conversion = dollarsInEuros().conversion
        #expect(conversion?.rate == rate092)
        #expect(conversion?.amount == 9_200)
        #expect(conversion?.currency == .eur)
    }
}
