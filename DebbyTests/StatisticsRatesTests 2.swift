//
//  StatisticsRatesTests 2.swift
//  Debby
//
//  Created by Shox on 29/10/26.
//


import Testing
import Foundation
import SwiftData
@testable import Debby

@MainActor
struct StatisticsRatesTests {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }
    let calendar: Calendar
    let person = Person(name: "Ali")
    let uzs = Currency(code: "UZS")
    let rub = Currency(code: "RUB")

    init() throws {
        container = try ModelContainer(
            for: Person.self, Entry.self, PaymentCard.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        self.calendar = calendar
        context.insert(person)
    }

    private func date(_ day: Int, _ hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour))!
    }

    private func exchange(
        _ amount: Decimal, _ from: Currency,
        gets counterAmount: Decimal, _ to: Currency,
        rate: String, day: Int, hour: Int = 12
    ) -> Entry {
        let entry = Entry(
            person: person, date: date(day, hour), direction: .received,
            amount: amount, currency: from,
            conversion: Conversion(currency: to, amount: counterAmount, rate: Decimal(string: rate)!)
        )
        context.insert(entry)
        return entry
    }

    private func close(_ a: Decimal, _ b: String, tolerance: String = "0.001") -> Bool {
        abs(a - Decimal(string: b)!) < Decimal(string: tolerance)!
    }

    @Test func oneDirectionAddsUpVolumeAndKeepsLowHighLatest() {
        let entries = [
            exchange(100, .usd, gets: 1_265_000, uzs, rate: "12650", day: 10),
            exchange(200, .usd, gets: 2_540_000, uzs, rate: "12700", day: 12)
        ]

        let summaries = entries.rateSummaries(period: .all)

        #expect(summaries.count == 1)
        let summary = summaries[0]
        #expect(summary.pair == CurrencyPair(base: .usd, quote: uzs))
        #expect(summary.operations == 2)
        #expect(summary.baseVolume == 30_000)
        #expect(summary.quoteVolume == 380_500_000)
        #expect(summary.lowest == 12_650)
        #expect(summary.highest == 12_700)
        #expect(summary.latest == 12_700)
        // (1.265.000 + 2.540.000) / 300 = 12683.33…, weighted by volume.
        #expect(close(summary.average, "12683.3333"))
    }

    @Test func theOppositeDirectionIsMergedIntoTheSamePair() {
        let entries = [
            exchange(100, .usd, gets: 1_265_000, uzs, rate: "12650", day: 10),
            // Entered the other way round: 1 UZS = 0,000079 USD.
            exchange(1_265_000, uzs, gets: Decimal(string: "99.94")!, .usd, rate: "0.000079", day: 12)
        ]

        let summaries = entries.rateSummaries(period: .all)

        #expect(summaries.count == 1)
        #expect(summaries[0].pair == CurrencyPair(base: .usd, quote: uzs))
        #expect(summaries[0].operations == 2)
        // 1 / 0,000079 = 12658.2278 and it is the more recent one.
        #expect(close(summaries[0].latest, "12658.2278"))
        #expect(summaries[0].baseVolume == 10_000 + 9_994)
    }

    @Test func entriesWithoutASecondCurrencyAreIgnored() {
        let plain = Entry(person: person, date: date(10), direction: .gave, amount: 100, currency: .usd)
        context.insert(plain)

        #expect([plain].rateSummaries(period: .all).isEmpty)
    }

    @Test func pairsAreSortedByNumberOfOperations() {
        let entries = [
            exchange(100, .usd, gets: 1_265_000, uzs, rate: "12650", day: 10),
            exchange(10, .eur, gets: 1_000, rub, rate: "100", day: 11),
            exchange(20, .eur, gets: 2_000, rub, rate: "100", day: 12)
        ]

        let summaries = entries.rateSummaries(period: .all)

        #expect(summaries.map(\.pair.id) == ["EUR/RUB", "USD/UZS"])
        #expect(summaries.map(\.operations) == [2, 1])
    }

    @Test func periodAndRangeLimitWhichExchangesCount() {
        let entries = [
            exchange(100, .usd, gets: 1_265_000, uzs, rate: "12650", day: 10),
            exchange(100, .usd, gets: 1_270_000, uzs, rate: "12700", day: 18)
        ]
        let now = date(18)

        let today = entries.rateSummaries(period: .today, now: now, calendar: calendar)
        let range = entries.rateSummaries(
            period: .custom,
            range: DayRange(from: date(9), to: date(11)),
            now: now, calendar: calendar
        )

        #expect(today.first?.operations == 1)
        #expect(today.first?.latest == 12_700)
        #expect(range.first?.operations == 1)
        #expect(range.first?.latest == 12_650)
    }
}