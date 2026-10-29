//
//  EntryGroupingTests.swift
//  DebbyTests
//
//  Created by Shox on 20/10/26.
//

import Testing
import Foundation
import SwiftData
@testable import Debby

@MainActor
struct EntryGroupingTests {
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

    private func date(_ day: Int, _ hour: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour))!
    }

    private func entry(for person: Person, at date: Date) -> Entry {
        let entry = Entry(person: person, date: date, direction: .gave, amount: 10, currency: .eur)
        context.insert(entry)
        return entry
    }

    @Test func groupsByDayNewestFirst() {
        let ali = Person(name: "Ali")
        context.insert(ali)
        let morning = entry(for: ali, at: date(18, 10))
        let evening = entry(for: ali, at: date(18, 20))
        let earlier = entry(for: ali, at: date(17, 9))

        let days = [morning, earlier, evening].groupedByDay(calendar: calendar)

        #expect(days.count == 2)
        #expect(days[0].entries.map(\.date) == [evening.date, morning.date])
        #expect(days[1].entries.map(\.date) == [earlier.date])
    }

    @Test func titlesTodayAndYesterday() {
        let ali = Person(name: "Ali")
        context.insert(ali)
        let now = date(18, 12)
        let today = entry(for: ali, at: date(18, 8))
        let yesterday = entry(for: ali, at: date(17, 8))

        let days = [today, yesterday].groupedByDay(calendar: calendar)

        #expect(days[0].title(now: now, calendar: calendar) == "Today")
        #expect(days[1].title(now: now, calendar: calendar) == "Yesterday")
    }

    @Test func emptyInputGivesNoGroups() {
        #expect([Entry]().groupedByDay(calendar: calendar).isEmpty)
    }
}
