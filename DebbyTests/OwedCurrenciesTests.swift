//
//  OwedCurrenciesTests.swift
//  DebbyTests
//
//  Created by Shox on 30/10/26.
//
import Testing
import SwiftData
import Foundation
@testable import Debby

@MainActor
struct OwedCurrenciesTests {
    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Person.self, Entry.self, PaymentCard.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    /// A new person with one entry: they owe you (you gave) or you owe them (you received).
    @discardableResult
    private func addPerson(
        _ name: String,
        in context: ModelContext,
        theyOweYou: Bool,
        amount: Decimal,
        currency: Currency
    ) -> Person {
        let person = Person(name: name)
        context.insert(person)
        context.insert(Entry(
            person: person,
            direction: theyOweYou ? .gave : .received,
            amount: amount,
            currency: currency
        ))
        return person
    }

    private func option(_ currency: Currency) -> OwedCurrency {
        OwedCurrency(currency: currency, total: 100, people: 1)
    }

    // MARK: Which currencies appear

    @Test func singleCurrencyShowsOnlyThatCurrency() throws {
        let container = try makeContainer()
        let context = container.mainContext
        addPerson("Ali", in: context, theyOweYou: true, amount: 100, currency: .eur)
        let people = try context.fetch(FetchDescriptor<Person>())

        let options = people.owedCurrencies(.owedToYou, preferred: .eur)

        #expect(options.map(\.currency) == [.eur])
        #expect(options.first?.total == 10_000)
        #expect(options.first?.people == 1)
        #expect(people.owedCurrencies(.youOwe, preferred: .eur).isEmpty)
    }

    @Test func eachSideHasItsOwnCurrencies() throws {
        let container = try makeContainer()
        let context = container.mainContext
        addPerson("Bob", in: context, theyOweYou: true, amount: 450, currency: .usd)
        addPerson("Carol", in: context, theyOweYou: true, amount: 76_500, currency: .rub)
        addPerson("Dan", in: context, theyOweYou: false, amount: 100, currency: .eur)
        let people = try context.fetch(FetchDescriptor<Person>())

        #expect(people.owedCurrencies(.owedToYou, preferred: .eur).map(\.currency) == [.rub, .usd])
        #expect(people.owedCurrencies(.youOwe, preferred: .eur).map(\.currency) == [.eur])
    }

    @Test func preferredCurrencyComesFirst() throws {
        let container = try makeContainer()
        let context = container.mainContext
        addPerson("Bob", in: context, theyOweYou: true, amount: 450, currency: .usd)
        addPerson("Carol", in: context, theyOweYou: true, amount: 76_500, currency: .rub)
        let people = try context.fetch(FetchDescriptor<Person>())

        #expect(people.owedCurrencies(.owedToYou, preferred: .usd).map(\.currency) == [.usd, .rub])
        #expect(people.owedCurrencies(.owedToYou, preferred: .rub).map(\.currency) == [.rub, .usd])
    }

    @Test func totalsAndPeopleAreCountedPerCurrency() throws {
        let container = try makeContainer()
        let context = container.mainContext
        addPerson("Ali", in: context, theyOweYou: true, amount: 100, currency: .eur)
        addPerson("Bob", in: context, theyOweYou: true, amount: 250, currency: .eur)
        let people = try context.fetch(FetchDescriptor<Person>())

        let options = people.owedCurrencies(.owedToYou, preferred: .eur)

        #expect(options.count == 1)
        #expect(options.first?.total == 35_000)
        #expect(options.first?.people == 2)
    }

    @Test func settledCurrencyDisappears() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let ali = addPerson("Ali", in: context, theyOweYou: true, amount: 100, currency: .eur)
        context.insert(Entry(person: ali, direction: .received, amount: 100, currency: .eur))
        let people = try context.fetch(FetchDescriptor<Person>())

        #expect(people.owedCurrencies(.owedToYou, preferred: .eur).isEmpty)
        #expect(people.owedCurrencies(.youOwe, preferred: .eur).isEmpty)
    }

    // MARK: Which chip is selected

    @Test func selectionStaysWhenItStillExists() {
        let options = [option(.eur), option(.usd)]
        #expect(OwedCurrency.resolve(selected: .usd, in: options) == .usd)
    }

    @Test func selectionFallsBackToTheFirstChip() {
        let options = [option(.eur), option(.usd)]
        #expect(OwedCurrency.resolve(selected: .rub, in: options) == .eur)
        #expect(OwedCurrency.resolve(selected: nil, in: options) == .eur)
    }

    @Test func noChipsMeansNoSelection() {
        #expect(OwedCurrency.resolve(selected: .eur, in: []) == nil)
    }
}
