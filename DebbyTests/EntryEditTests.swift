//
//  EntryEditTests.swift
//  DebbyTests
//
//  Created by Shox on 19/10/26.
//

import Testing
import Foundation
import SwiftData
@testable import Debby

@MainActor
struct EntryEditTests {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }
    let rate = Decimal(string: "0.92")!

    init() throws {
        container = try ModelContainer(
            for: Person.self, Entry.self, PaymentCard.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    @Test func addingASecondCurrencyMovesTheBalance() {
        let ali = Person(name: "Ali")
        context.insert(ali)
        let entry = Entry(person: ali, direction: .received, amount: 10_000, currency: .usd)
        context.insert(entry)
        #expect(ali.balance(in: .usd) == -10_000)

        entry.update(
            person: ali, date: entry.date, direction: .received, amount: 10_000, currency: .usd,
            conversion: Conversion(currency: .eur, amount: 9_200, rate: rate), note: ""
        )

        #expect(ali.balance(in: .usd) == 0)
        #expect(ali.balance(in: .eur) == -9_200)
    }

    @Test func removingTheSecondCurrencyPutsTheBalanceBack() {
        let ali = Person(name: "Ali")
        context.insert(ali)
        let entry = Entry(person: ali, direction: .received, amount: 10_000, currency: .usd,
                          conversion: Conversion(currency: .eur, amount: 9_200, rate: rate))
        context.insert(entry)
        #expect(ali.balance(in: .eur) == -9_200)

        entry.update(
            person: ali, date: entry.date, direction: .received, amount: 10_000, currency: .usd,
            conversion: nil, note: ""
        )

        #expect(ali.balance(in: .eur) == 0)
        #expect(ali.balance(in: .usd) == -10_000)
    }

    @Test func movingAnEntryToAnotherPerson() {
        let ali = Person(name: "Ali")
        let bob = Person(name: "Bob")
        context.insert(ali)
        context.insert(bob)
        let entry = Entry(person: ali, direction: .gave, amount: 100, currency: .eur)
        context.insert(entry)

        entry.update(
            person: bob, date: entry.date, direction: .gave, amount: 100, currency: .eur,
            conversion: nil, note: "wrong person"
        )

        #expect(ali.balance(in: .eur) == 0)
        #expect(bob.balance(in: .eur) == 100)
        #expect(entry.note == "wrong person")
    }

    @Test func changingTheAmountAndDirection() {
        let ali = Person(name: "Ali")
        context.insert(ali)
        let entry = Entry(person: ali, direction: .gave, amount: 100, currency: .eur)
        context.insert(entry)

        entry.update(
            person: ali, date: entry.date, direction: .received, amount: Decimal(string: "12.50")!,
            currency: .eur, conversion: nil, note: ""
        )

        #expect(ali.balance(in: .eur) == Decimal(string: "-12.5"))
    }
}
