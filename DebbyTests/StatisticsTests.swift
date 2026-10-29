//
//  StatisticsTests.swift
//  DebbyTests
//
//  Created by Shox on 22/10/26.
//

import Testing
import Foundation
import SwiftData
@testable import Debby

@MainActor
struct StatisticsTests {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }
    let calendar: Calendar

    init() throws {
        container = try ModelContainer(
            for: Person.self, Entry.self, PaymentCard.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        self.calendar = calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    @discardableResult
    private func add(
        _ person: Person, _ direction: Direction, _ amount: Decimal,
        _ currency: Currency = .eur, on date: Date = .now
    ) -> Entry {
        let entry = Entry(person: person, date: date, direction: direction,
                          amount: amount, currency: currency)
        context.insert(entry)
        return entry
    }

    private func newPerson(_ name: String) -> Person {
        let person = Person(name: name)
        context.insert(person)
        return person
    }

    // MARK: Snapshot

    @Test func snapshotCountsBothSidesAndSkipsSettledPeople() {
        let ali = newPerson("Ali")
        let bob = newPerson("Bob")
        let cara = newPerson("Cara")
        add(ali, .gave, 100)
        add(bob, .received, 50)
        add(cara, .gave, 80)
        add(cara, .received, 80)

        let snapshot = [ali, bob, cara].statsSnapshot(in: .eur)

        #expect(snapshot.owedToYou == 10_000)
        #expect(snapshot.youOwe == 5_000)
        #expect(snapshot.net == 5_000)
        #expect(snapshot.openBalances == 2)
    }

    @Test func snapshotIsPerCurrency() {
        let ali = newPerson("Ali")
        add(ali, .gave, 100, .usd)

        #expect([ali].statsSnapshot(in: .eur).openBalances == 0)
        #expect([ali].statsSnapshot(in: .usd).owedToYou == 10_000)
    }

    // MARK: Cash flow

    @Test func cashFlowAddsUpReceivedAndGave() {
        let ali = newPerson("Ali")
        let entries = [
            add(ali, .gave, 100),
            add(ali, .received, 300),
            add(ali, .gave, 50)
        ]

        let flow = entries.cashFlow(in: .eur, period: .all)

        #expect(flow.received == 30_000)
        #expect(flow.gave == 15_000)
        #expect(flow.net == 15_000)
        #expect(flow.operations == 3)
    }

    @Test func cashFlowFollowsTheCashCurrencyNotTheBalanceCurrency() {
        let ali = newPerson("Ali")
        // 10.000 $ in cash; the balance moves in euros.
        let entry = Entry(
            person: ali, direction: .received, amount: 10_000, currency: .usd,
            conversion: Conversion(currency: .eur, amount: 9_200, rate: Decimal(string: "0.92")!)
        )
        context.insert(entry)

        #expect([entry].cashFlow(in: .usd, period: .all).received == 1_000_000)
        #expect([entry].cashFlow(in: .eur, period: .all).operations == 0)
    }

    @Test func periodsFilterByDate() {
        let ali = newPerson("Ali")
        let now = date(2026, 10, 18)
        let entries = [
            add(ali, .gave, 10, on: date(2026, 10, 18, 8)),    // today
            add(ali, .gave, 10, on: date(2026, 10, 12, 23)),   // late evening
            add(ali, .gave, 10, on: date(2026, 10, 11, 1)),    // just after midnight
            add(ali, .gave, 10, on: date(2026, 9, 30, 9)),     // last month
            add(ali, .gave, 10, on: date(2025, 12, 31, 9))     // last year
        ]

        func count(_ period: StatsPeriod, range: DayRange? = nil) -> Int {
            entries.cashFlow(in: .eur, period: period, range: range, now: now, calendar: calendar).operations
        }

        #expect(count(.today) == 1)
        #expect(count(.month) == 3)
        #expect(count(.all) == 5)
    }

    @Test func customRangeIncludesWholeDaysAtBothEnds() {
        let ali = newPerson("Ali")
        let entries = [
            add(ali, .gave, 10, on: date(2026, 10, 18, 8)),
            add(ali, .gave, 10, on: date(2026, 10, 12, 23)),
            add(ali, .gave, 10, on: date(2026, 10, 11, 1)),
            add(ali, .gave, 10, on: date(2026, 9, 30, 9)),
            add(ali, .gave, 10, on: date(2025, 12, 31, 9))
        ]

        func count(_ from: Date, _ to: Date) -> Int {
            entries.cashFlow(
                in: .eur, period: .custom, range: DayRange(from: from, to: to), calendar: calendar
            ).operations
        }

        // 11 Oct 01:00 and 12 Oct 23:00 are both inside "11 to 12 Oct".
        #expect(count(date(2026, 10, 11), date(2026, 10, 12)) == 2)
        // Picking the dates in the wrong order gives the same answer.
        #expect(count(date(2026, 10, 12), date(2026, 10, 11)) == 2)
        // A single day.
        #expect(count(date(2026, 10, 18), date(2026, 10, 18)) == 1)
        // Across a month boundary.
        #expect(count(date(2026, 9, 30), date(2026, 10, 11)) == 2)
        // Without a range, custom behaves like "all".
        #expect(entries.cashFlow(in: .eur, period: .custom, calendar: calendar).operations == 5)
    }

    @Test func cashFlowGroupsByDayOldestFirst() {
        let ali = newPerson("Ali")
        let entries = [
            add(ali, .received, 100, on: date(2026, 10, 18, 20)),
            add(ali, .gave, 40, on: date(2026, 10, 18, 9)),
            add(ali, .received, 5, on: date(2026, 10, 17, 10))
        ]

        let days = entries.cashFlow(in: .eur, period: .all, calendar: calendar).days

        #expect(days.count == 2)
        #expect(days[0].day < days[1].day)
        #expect(days[0].received == 500)
        #expect(days[1].received == 10_000)
        #expect(days[1].gave == 4_000)
    }
}
