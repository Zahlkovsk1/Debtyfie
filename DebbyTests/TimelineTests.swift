//
//  TimelineTests.swift
//  DebbyTests
//
//  Created by Shox on 21/10/26.
//

import Testing
import Foundation
import SwiftData
@testable import Debby

@MainActor
struct TimelineTests {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }
    let person = Person(name: "Ali")

    init() throws {
        container = try ModelContainer(
            for: Person.self, Entry.self, PaymentCard.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context.insert(person)
    }

    @discardableResult
    private func add(_ direction: Direction, _ amount: Decimal, minute: Int,
                     currency: Currency = .eur) -> Entry {
        let date = Date(timeIntervalSince1970: 1_800_000_000 + Double(minute) * 60)
        let entry = Entry(person: person, date: date, direction: direction,
                          amount: amount, currency: currency)
        context.insert(entry)
        return entry
    }

    @Test func aDebtPaidBackInPartsIsOneSettledPhase() {
        let entries = [
            add(.gave, 1_000, minute: 0),
            add(.received, 400, minute: 1),
            add(.received, 600, minute: 2)
        ]

        let phases = entries.timelinePhases(in: .eur)

        #expect(phases.count == 1)
        #expect(phases[0].status == .settled)
        #expect(phases[0].events.map(\.kind) == [.started, .decreased, .settled])
        #expect(phases[0].peak == 100_000)
        #expect(phases[0].progress == 1)
        #expect(phases[0].remaining == 0)
    }

    @Test func moreOwedInTheSameDirectionIncreases() {
        let entries = [add(.gave, 100, minute: 0), add(.gave, 50, minute: 1)]

        let phase = entries.timelinePhases(in: .eur)[0]

        #expect(phase.status == .open)
        #expect(phase.events.map(\.kind) == [.started, .increased])
        #expect(phase.remaining == 15_000)
        #expect(phase.peak == 15_000)
        #expect(phase.progress == 0)
    }

    @Test func partialPaymentMovesTheProgressBar() {
        let entries = [add(.gave, 100, minute: 0), add(.received, 40, minute: 1)]

        let phase = entries.timelinePhases(in: .eur)[0]

        #expect(phase.remaining == 6_000)
        #expect(abs(phase.progress - 0.4) < 0.0001)
    }

    @Test func crossingZeroEndsOnePhaseAndStartsAnother() {
        let entries = [add(.gave, 100, minute: 0), add(.received, 150, minute: 1)]

        let phases = entries.timelinePhases(in: .eur)

        #expect(phases.count == 2)
        // Newest first.
        #expect(phases[0].side == .youOwe)
        #expect(phases[0].status == .open)
        #expect(phases[0].remaining == 5_000)
        #expect(phases[0].events.map(\.kind) == [.started])
        #expect(phases[1].side == .owedToYou)
        #expect(phases[1].status == .directionChanged)
        #expect(phases[1].events.map(\.kind) == [.started, .flipped])
    }

    @Test func settlingThenOwingAgainStartsANewPhase() {
        let entries = [
            add(.gave, 100, minute: 0),
            add(.received, 100, minute: 1),
            add(.gave, 30, minute: 2)
        ]

        let phases = entries.timelinePhases(in: .eur)

        #expect(phases.count == 2)
        #expect(phases[0].status == .open)
        #expect(phases[0].remaining == 3_000)
        #expect(phases[1].status == .settled)
    }

    @Test func otherCurrenciesAreIgnored() {
        let entries = [add(.gave, 100, minute: 0, currency: .usd)]

        #expect(entries.timelinePhases(in: .eur).isEmpty)
        #expect(entries.timelinePhases(in: .usd).count == 1)
    }

    @Test func aSecondCurrencyEntryCountsInTheCurrencyTheBalanceMovesIn() {
        let entry = Entry(
            person: person, direction: .received, amount: 10_000, currency: .usd,
            conversion: Conversion(currency: .eur, amount: 9_200, rate: Decimal(string: "0.92")!)
        )
        context.insert(entry)

        let phases = [entry].timelinePhases(in: .eur)

        #expect(phases.count == 1)
        #expect(phases[0].side == .youOwe)
        #expect(phases[0].remaining == 920_000)
        #expect([entry].timelinePhases(in: .usd).isEmpty)
    }
}
