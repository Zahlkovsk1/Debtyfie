//
//  EntryGrouping.swift
//  Debby
//
//  Created by Shox on 20/10/26.
//

import Foundation

/// All entries of one calendar day, newest first.
struct EntryDay: Identifiable {
    let day: Date          // midnight of that day
    let entries: [Entry]

    var id: Date { day }

    /// "Today", "Yesterday", or "18 October" (with the year if it isn't this year).
    func title(now: Date = .now, calendar: Calendar = .current) -> String {
        if calendar.isDate(day, inSameDayAs: now) {
            return String(localized: "Today")
        }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(day, inSameDayAs: yesterday) {
            return String(localized: "Yesterday")
        }
        if calendar.isDate(day, equalTo: now, toGranularity: .year) {
            return day.formatted(.dateTime.day().month(.wide))
        }
        return day.formatted(.dateTime.day().month(.wide).year())
    }
}

extension Sequence where Element == Entry {
    /// Groups entries by calendar day: newest day first, newest entry first inside it.
    func groupedByDay(calendar: Calendar = .current) -> [EntryDay] {
        let byDay = Dictionary(grouping: self) { calendar.startOfDay(for: $0.date) }
        return byDay.keys.sorted(by: >).map { day in
            EntryDay(day: day, entries: byDay[day, default: []].sorted { $0.date > $1.date })
        }
    }
}
