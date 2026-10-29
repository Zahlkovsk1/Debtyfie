//
//  OwedSummaryTests.swift
//  DebbyTests
//
//  Created by Shox on 21/10/26.
//

import Testing
import Foundation
import SwiftData
@testable import Debby

@MainActor
struct OwedSummaryTests {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    init() throws {
        container = try ModelContainer(
            for: Person.self, Entry.self, PaymentCard.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func person(_ name: String, _ direction: Direction, _ amount: Decimal, _ currency: Currency) -> Person {
        let person = Person(name: name)
        context.insert(person)
        context.insert(Entry(person: person, direction: direction, amount: amount, currency: currency))
        return person
    }

    @Test func splitsPeopleBySideInOneCurrency() {
        let ali = person("Ali", .gave, 100, .eur)          // owes you 100 €
        let bob = person("Bob", .received, 50, .eur)       // you owe 50 €
        let dina = person("Dina", .gave, 30, .usd)         // owes you 30 $, nothing in €
        let settled = Person(name: "Cara")
        context.insert(settled)
        let people = [ali, bob, dina, settled]

        let owedToYou = people.owedSummary(.owedToYou, in: .eur)
        let youOwe = people.owedSummary(.youOwe, in: .eur)

        #expect(owedToYou.rows.map(\.person.name) == ["Ali"])
        #expect(owedToYou.total == 10_000)
        #expect(youOwe.rows.map(\.person.name) == ["Bob"])
        #expect(youOwe.total == 5_000)
    }

    @Test func otherCurrencyIsSeparate() {
        let dina = person("Dina", .gave, 30, .usd)

        #expect([dina].owedSummary(.owedToYou, in: .eur).rows.isEmpty)
        #expect([dina].owedSummary(.owedToYou, in: .usd).total == 3_000)
    }

    @Test func totalAddsUpEveryone() {
        let ali = person("Ali", .gave, 100, .eur)
        let bob = person("Bob", .gave, Decimal(string: "20.50")!, .eur)

        #expect([ali, bob].owedSummary(.owedToYou, in: .eur).total == 12_050)
    }
}
