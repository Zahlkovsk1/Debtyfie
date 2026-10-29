//
//  Statistics.swift
//  Debby
//
//  Created by Shox on 22/10/26.
//

import Foundation
import SwiftUI

// MARK: - Period
/// A span of whole calendar days, both ends included. If `from` is after `to`,
/// the two are swapped, so the order the user picks them in doesn't matter.
struct DayRange: Equatable {
    var from: Date
    var to: Date

    func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
        let first = min(from, to)
        let last = max(from, to)
        let start = calendar.startOfDay(for: first)
        guard let end = calendar.date(
            byAdding: .day, value: 1, to: calendar.startOfDay(for: last)
        ) else { return false }
        return date >= start && date < end
    }
}

enum StatsPeriod: String, CaseIterable, Identifiable {
    case today, month, all, custom

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .today: "Today"
        case .month: "Month"
        case .all: "All"
        case .custom: "Range"
        }
    }

    /// Whether `date` falls inside the period. `range` is only used for `.custom`.
    /// Month is the calendar month that contains `now`.
    func contains(
        _ date: Date,
        range: DayRange? = nil,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Bool {
        switch self {
        case .today:
            return calendar.isDate(date, inSameDayAs: now)
        case .month:
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
        case .all:
            return true
        case .custom:
            return range?.contains(date, calendar: calendar) ?? true
        }
    }
}

// MARK: - Section 1: where things stand now

struct StatsSnapshot {
    /// Minor units of the currency.
    let owedToYou: Int
    let youOwe: Int
    /// How many people have an open balance on either side.
    let openBalances: Int

    var net: Int { owedToYou - youOwe }
}

extension Sequence where Element == Person {
    func statsSnapshot(in currency: Currency) -> StatsSnapshot {
        let people = Array(self)
        let owed = people.owedSummary(.owedToYou, in: currency)
        let owe = people.owedSummary(.youOwe, in: currency)
        return StatsSnapshot(
            owedToYou: owed.total,
            youOwe: owe.total,
            openBalances: owed.rows.count + owe.rows.count
        )
    }
}

// MARK: - Section 2: cash flow

struct CashFlowDay: Identifiable {
    let day: Date          // midnight of that day
    var received: Int
    var gave: Int
    var entries: [Entry] = []

    var id: Date { day }
}

struct CashFlow {
    var received = 0       // minor units
    var gave = 0
    var operations = 0
    /// Days that had at least one operation, oldest first.
    var days: [CashFlowDay] = []

    /// Change in cash: positive means more came in than went out.
    var net: Int { received - gave }
}

extension Sequence where Element == Entry {
    /// The cash that moved in `currency` during `period`. It counts the entry's own
    /// currency, the money that changed hands, not the currency the balance moved in.
    func cashFlow(
          in currency: Currency,
          period: StatsPeriod,
          range: DayRange? = nil,
          now: Date = .now,
          calendar: Calendar = .current
      ) -> CashFlow {
          let inScope = filter {
              $0.currency == currency
                  && period.contains($0.date, range: range, now: now, calendar: calendar)
          }

        var flow = CashFlow()
        var byDay: [Date: CashFlowDay] = [:]

        for entry in inScope {
            let day = calendar.startOfDay(for: entry.date)
            var bucket = byDay[day] ?? CashFlowDay(day: day, received: 0, gave: 0)

            switch entry.direction {
            case .received:
                flow.received += entry.amountMinor
                bucket.received += entry.amountMinor
            case .gave:
                flow.gave += entry.amountMinor
                bucket.gave += entry.amountMinor
            }
            
            bucket.entries.append(entry)
            byDay[day] = bucket
            flow.operations += 1
        }

        flow.days = byDay.values
            .sorted { $0.day < $1.day }
            .map { day in
                var day = day
                day.entries.sort { $0.date > $1.date }   // newest first inside a day
                return day
            }
        return flow
    }
}
