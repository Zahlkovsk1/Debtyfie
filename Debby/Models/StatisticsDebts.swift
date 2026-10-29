//
//  StatisticsDebts.swift
//  Debby
//
//  Created by Shox on 23/10/26.
//

import Foundation
import SwiftUI

// MARK: - Section 3: biggest balances

extension Sequence where Element == Person {
    /// The biggest balances on one side, largest first. Ties are ordered by name.
    func topBalances(_ side: OwedSide, in currency: Currency, limit: Int = 5) -> [OwedSummary.Row] {
        let rows = owedSummary(side, in: currency).rows.sorted {
            if $0.minorUnits != $1.minorUnits { return $0.minorUnits > $1.minorUnits }
            return $0.person.name.localizedStandardCompare($1.person.name) == .orderedAscending
        }
        return Array(rows.prefix(limit))
    }
}

// MARK: - Section 4: how old the debts are

enum DebtAge: CaseIterable, Identifiable {
    case fresh   // under 30 days
    case middle  // 30 to 90 days
    case old     // over 90 days

    var id: Self { self }

    init(days: Int) {
        switch days {
        case ..<30: self = .fresh
        case 30...90: self = .middle
        default: self = .old
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .fresh: "Under 30 days"
        case .middle: "30–90 days"
        case .old: "Over 90 days"
        }
    }
}

/// One person who owes you, with how long the current debt has been open.
struct AgedDebt: Identifiable {
    let person: Person
    /// What is still owed, in minor units.
    let minorUnits: Int
    /// When the current debt began: the last time the balance left zero.
    let since: Date
    let days: Int

    var id: UUID { person.id }
    var age: DebtAge { DebtAge(days: days) }
    static let followUpAfterDays = 30
    var needsFollowUp: Bool { days >= Self.followUpAfterDays }
}

struct AgeBucket: Identifiable {
    let age: DebtAge
    let total: Int
    let count: Int

    var id: DebtAge { age }
}

struct DebtAging {
    /// Oldest debt first, so the first row is the one to follow up.
    let debts: [AgedDebt]

    /// Every age group, including empty ones.
    var buckets: [AgeBucket] {
        DebtAge.allCases.map { age in
            let inGroup = debts.filter { $0.age == age }
            return AgeBucket(age: age, total: inGroup.reduce(0) { $0 + $1.minorUnits }, count: inGroup.count)
        }
    }
    /// The biggest debts first. Equal amounts go oldest first.
    func biggest(limit: Int = 5) -> [AgedDebt] {
        let sorted = debts.sorted {
            if $0.minorUnits != $1.minorUnits { return $0.minorUnits > $1.minorUnits }
            return $0.days > $1.days
        }
        return Array(sorted.prefix(limit))
    }
}

extension Sequence where Element == Person {
    /// The debts people owe you in `currency`, with their age measured from the
    /// start of the current phase. Partial payments do not restart the clock.
    func debtAging(
        _ side: OwedSide = .owedToYou,
        in currency: Currency,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> DebtAging {
        let debts = compactMap { person -> AgedDebt? in
            guard let phase = person.entries.timelinePhases(in: currency).first,
                  phase.status == .open,
                  phase.side == side else { return nil }

            let days = calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: phase.start),
                to: calendar.startOfDay(for: now)
            ).day ?? 0

            return AgedDebt(
                person: person,
                minorUnits: phase.remaining,
                since: phase.start,
                days: Swift.max(0, days)
            )
        }

        return DebtAging(debts: debts.sorted {
            if $0.days != $1.days { return $0.days > $1.days }
            return $0.minorUnits > $1.minorUnits
        })
    }
}
