//
//  StatisticsDebtsTests.swift
//  DebbyTests
//
//  Created by Shox on 23/10/26.
//

import Testing
import Foundation
import SwiftData
@testable import Debby

@MainActor
struct StatisticsDebtsTests {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }
    let calendar: Calendar
    let now: Date

    init() throws {
        container = try ModelContainer(
            for: Person.self, Entry.self, PaymentCard.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        self.calendar = calendar
        now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 18, hour: 12))!
    }

    private func newPerson(_ name: String) -> Person {
        let person = Person(name: name)
        context.insert(person)
        return person
    }

    @discardableResult
    private func add(
        _ person: Person, _ direction: Direction, _ amount: Decimal,
        daysAgo: Int, _ currency: Currency = .eur
    ) -> Entry {
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
        let entry = Entry(person: person, date: date, direction: direction,
                          amount: amount, currency: currency)
        context.insert(entry)
        return entry
    }

    // MARK: Top balances

    @Test func topBalancesAreLargestFirstAndLimited() {
        let ali = newPerson("Ali")
        let bob = newPerson("Bob")
        let cara = newPerson("Cara")
        add(ali, .gave, 100, daysAgo: 1)
        add(bob, .gave, 300, daysAgo: 1)
        add(cara, .gave, 200, daysAgo: 1)

        let top = [ali, bob, cara].topBalances(.owedToYou, in: .eur, limit: 2)

        #expect(top.map(\.person.name) == ["Bob", "Cara"])
        #expect(top.map(\.minorUnits) == [30_000, 20_000])
    }

    @Test func equalBalancesAreOrderedByName() {
        let zoe = newPerson("Zoe")
        let ann = newPerson("Ann")
        add(zoe, .gave, 100, daysAgo: 1)
        add(ann, .gave, 100, daysAgo: 1)

        let top = [zoe, ann].topBalances(.owedToYou, in: .eur)

        #expect(top.map(\.person.name) == ["Ann", "Zoe"])
    }

    @Test func topBalancesForTheSideYouOwe() {
        let ali = newPerson("Ali")
        let bob = newPerson("Bob")
        add(ali, .received, 40, daysAgo: 1)
        add(bob, .gave, 500, daysAgo: 1)

        let top = [ali, bob].topBalances(.youOwe, in: .eur)

        #expect(top.map(\.person.name) == ["Ali"])
    }

    // MARK: Age groups

    @Test func ageGroupBoundaries() {
        #expect(DebtAge(days: 0) == .fresh)
        #expect(DebtAge(days: 29) == .fresh)
        #expect(DebtAge(days: 30) == .middle)
        #expect(DebtAge(days: 90) == .middle)
        #expect(DebtAge(days: 91) == .old)
    }

    @Test func ageStartsWhereTheCurrentDebtStarted() {
        let ali = newPerson("Ali")
        add(ali, .gave, 100, daysAgo: 100)
        add(ali, .received, 40, daysAgo: 5)   // partial payment: the clock keeps running

        let aging = [ali].debtAging(in: .eur, now: now, calendar: calendar)

        #expect(aging.debts.count == 1)
        #expect(aging.debts[0].days == 100)
        #expect(aging.debts[0].minorUnits == 6_000)
        #expect(aging.debts[0].age == .old)
    }

    @Test func aSettledDebtRestartsTheClockWhenPeopleOweAgain() {
        let ali = newPerson("Ali")
        add(ali, .gave, 100, daysAgo: 90)
        add(ali, .received, 100, daysAgo: 80)  // settled
        add(ali, .gave, 20, daysAgo: 3)        // a new debt

        let aging = [ali].debtAging(in: .eur, now: now, calendar: calendar)

        #expect(aging.debts[0].days == 3)
        #expect(aging.debts[0].minorUnits == 2_000)
        #expect(aging.debts[0].age == .fresh)
    }

    @Test func onlyDebtsOwedToYouInTheCurrencyCount() {
        let owes = newPerson("Owes")
        let youOwe = newPerson("YouOwe")
        let settled = newPerson("Settled")
        let dollars = newPerson("Dollars")
        add(owes, .gave, 100, daysAgo: 10)
        add(youOwe, .received, 100, daysAgo: 10)
        add(settled, .gave, 50, daysAgo: 10)
        add(settled, .received, 50, daysAgo: 9)
        add(dollars, .gave, 100, daysAgo: 10, .usd)

        let aging = [owes, youOwe, settled, dollars].debtAging(in: .eur, now: now, calendar: calendar)

        #expect(aging.debts.map(\.person.name) == ["Owes"])
    }

    @Test func bucketsAddUpAndOldestDebtComesFirst() {
        let ali = newPerson("Ali")
        let bob = newPerson("Bob")
        let cara = newPerson("Cara")
        let dina = newPerson("Dina")
        add(ali, .gave, 100, daysAgo: 50)                      // middle
        add(bob, .gave, 50, daysAgo: 10)                       // fresh
        add(cara, .gave, 100, daysAgo: 100)                    // old, 60 left
        add(cara, .received, 40, daysAgo: 5)
        add(dina, .gave, 20, daysAgo: 3)                       // fresh

        let aging = [ali, bob, cara, dina].debtAging(in: .eur, now: now, calendar: calendar)
        let buckets = Dictionary(uniqueKeysWithValues: aging.buckets.map { ($0.age, $0) })

        #expect(aging.debts.map(\.person.name) == ["Cara", "Ali", "Bob", "Dina"])
        #expect(buckets[.fresh]?.total == 7_000)
        #expect(buckets[.fresh]?.count == 2)
        #expect(buckets[.middle]?.total == 10_000)
        #expect(buckets[.middle]?.count == 1)
        #expect(buckets[.old]?.total == 6_000)
        #expect(buckets[.old]?.count == 1)
    }
    
    @Test func debtsYouOweAreAgedToo() {
        let ali = newPerson("Ali")
        add(ali, .received, 100, daysAgo: 40)

        let youOwe = [ali].debtAging(.youOwe, in: .eur, now: now, calendar: calendar)
        let owedToYou = [ali].debtAging(.owedToYou, in: .eur, now: now, calendar: calendar)

        #expect(youOwe.debts.count == 1)
        #expect(youOwe.debts[0].days == 40)
        #expect(youOwe.debts[0].minorUnits == 10_000)
        #expect(owedToYou.debts.isEmpty)
    }

    @Test func followUpStartsAtThirtyDays() {
        let ali = newPerson("Ali")
        let bob = newPerson("Bob")
        add(ali, .gave, 10, daysAgo: 29)
        add(bob, .gave, 10, daysAgo: 30)

        let debts = [ali, bob].debtAging(in: .eur, now: now, calendar: calendar).debts

        #expect(debts.map(\.person.name) == ["Bob", "Ali"])   // oldest first
        #expect(debts.map(\.needsFollowUp) == [true, false])
    }

    @Test func biggestDebtsComeFirstAndAreLimited() {
        let ali = newPerson("Ali")
        let bob = newPerson("Bob")
        let cara = newPerson("Cara")
        let dina = newPerson("Dina")
        add(ali, .gave, 100, daysAgo: 5)
        add(bob, .gave, 300, daysAgo: 1)
        add(cara, .gave, 200, daysAgo: 10)
        add(dina, .gave, 200, daysAgo: 20)

        let top = [ali, bob, cara, dina]
            .debtAging(in: .eur, now: now, calendar: calendar)
            .biggest(limit: 3)

        // 300 first, then the two 200s with the older one first.
        #expect(top.map(\.person.name) == ["Bob", "Dina", "Cara"])
    }
}
