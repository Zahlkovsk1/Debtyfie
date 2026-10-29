//
//  Timeline.swift
//  Debby
//
//  Created by Shox on 21/10/26.
//

import Foundation

enum TimelineEventKind {
    case started      // the balance left zero
    case increased    // more owed, same direction
    case decreased    // a partial payment
    case settled      // the balance came back to exactly zero
    case flipped      // the balance crossed zero and changed direction
}

struct TimelineEvent: Identifiable {
    let entry: Entry
    let kind: TimelineEventKind
    /// Balance after this entry in minor units, signed: positive means they owe you.
    let balanceAfter: Int

    var id: UUID { entry.id }
}

enum TimelinePhaseStatus {
    case open
    case settled
    case directionChanged
}

/// One stretch of the ledger between two "zero" moments.
struct TimelinePhase: Identifiable {
    let side: OwedSide
    private(set) var events: [TimelineEvent]      // oldest first
    fileprivate(set) var status: TimelinePhaseStatus = .open
    /// The largest amount owed at any moment in this phase, in minor units.
    private(set) var peak: Int

    var id: UUID { events[0].entry.id }

    var start: Date { events[0].entry.date }

    /// When the phase ended, or nil while it is still open.
    var end: Date? { status == .open ? nil : events.last?.entry.date }

    /// What is still owed in this phase, in minor units. Zero once it has ended.
    var remaining: Int {
        status == .open ? abs(events.last?.balanceAfter ?? 0) : 0
    }

    /// How much of the peak has been paid back, from 0 to 1.
    var progress: Double {
        guard status == .open else { return 1 }
        guard peak > 0 else { return 0 }
        return 1 - Double(remaining) / Double(peak)
    }

    fileprivate init(entry: Entry, balance: Int) {
        side = balance > 0 ? .owedToYou : .youOwe
        events = [TimelineEvent(entry: entry, kind: .started, balanceAfter: balance)]
        peak = abs(balance)
    }

    fileprivate mutating func add(_ entry: Entry, _ kind: TimelineEventKind, balance: Int) {
        events.append(TimelineEvent(entry: entry, kind: kind, balanceAfter: balance))
        peak = max(peak, abs(balance))
    }
}

extension Sequence where Element == Entry {
    /// The phases of the ledger in `currency`, newest first. Entries in other
    /// currencies are ignored.
    func timelinePhases(in currency: Currency) -> [TimelinePhase] {
        let ordered = filter { $0.ledgerCurrency == currency }
            .sorted { ($0.date, $0.createdAt) < ($1.date, $1.createdAt) }

        var finished: [TimelinePhase] = []
        var open: TimelinePhase?
        var balance = 0

        for entry in ordered {
            let delta = abs(entry.ledgerMinorUnits) * (entry.direction == .gave ? 1 : -1)
            guard delta != 0 else { continue }

            let before = balance
            balance += delta

            guard var phase = open else {
                // The balance was zero: a new phase begins.
                open = TimelinePhase(entry: entry, balance: balance)
                continue
            }

            if balance == 0 {
                phase.add(entry, .settled, balance: balance)
                phase.status = .settled
                finished.append(phase)
                open = nil
            } else if (before > 0) != (balance > 0) {
                // Crossed zero: this phase ends, a new one starts with the rest.
                phase.add(entry, .flipped, balance: balance)
                phase.status = .directionChanged
                finished.append(phase)
                open = TimelinePhase(entry: entry, balance: balance)
            } else {
                phase.add(entry, abs(balance) > abs(before) ? .increased : .decreased, balance: balance)
                open = phase
            }
        }

        if let open { finished.append(open) }
        return finished.reversed()
    }
}
