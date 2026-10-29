//
//  OwedSummary.swift
//  Debby
//
//  Created by Shox on 21/10/26.
//

import Foundation

enum OwedSide: CaseIterable {
    case owedToYou
    case youOwe
}

/// Who is on one side of the ledger in one currency, and how much in total.
struct OwedSummary {
    struct Row: Identifiable {
        let person: Person
        /// Always positive, in minor units of the currency.
        let minorUnits: Int

        var id: UUID { person.id }
    }

    let rows: [Row]

    var total: Int { rows.reduce(0) { $0 + $1.minorUnits } }
}

extension Sequence where Element == Person {
    /// People whose balance in `currency` is on the given side. Settled people are left out.
    func owedSummary(_ side: OwedSide, in currency: Currency) -> OwedSummary {
        let rows = compactMap { person -> OwedSummary.Row? in
            let balance = person.balances[currency] ?? 0
            switch side {
            case .owedToYou:
                return balance > 0 ? OwedSummary.Row(person: person, minorUnits: balance) : nil
            case .youOwe:
                return balance < 0 ? OwedSummary.Row(person: person, minorUnits: -balance) : nil
            }
        }
        return OwedSummary(rows: rows)
    }
}
