//
//  OwedCurrencies.swift
//  Debby
//
//  Created by Shox on 30/10/26.
//

import Foundation

/// One currency chip on the Owed screen: a currency with open balances on one side.
struct OwedCurrency: Identifiable, Equatable {
    var currency: Currency
    /// All open balances in this currency added up, in minor units. Always positive.
    var total: Int
    /// How many people make up that total.
    var people: Int

    var id: String { currency.code }
}

extension OwedCurrency {
    /// Which currency should be selected: the current choice if it still exists on this
    /// side, otherwise the first chip, or nil when the side has no balances at all.
    static func resolve(selected: Currency?, in options: [OwedCurrency]) -> Currency? {
        if let selected, options.contains(where: { $0.currency == selected }) {
            return selected
        }
        return options.first?.currency
    }
}

extension Array where Element == Person {
    /// The currencies that have open balances on the given side, in a fixed order:
    /// the preferred currency first, then the rest by currency code. Amounts in
    /// different currencies can't be compared, so they are never sorted by size.
    func owedCurrencies(_ side: OwedSide, preferred: Currency) -> [OwedCurrency] {
        var currencies = Set<Currency>()
        for person in self {
            currencies.formUnion(person.balances.keys)
        }

        let options = currencies.compactMap { currency -> OwedCurrency? in
            let summary = owedSummary(side, in: currency)
            guard !summary.rows.isEmpty else { return nil }
            return OwedCurrency(
                currency: currency,
                total: summary.total,
                people: summary.rows.count
            )
        }

        return options.sorted { lhs, rhs in
            let lhsPreferred = lhs.currency == preferred
            let rhsPreferred = rhs.currency == preferred
            if lhsPreferred != rhsPreferred { return lhsPreferred }
            return lhs.currency.code < rhs.currency.code
        }
    }
}
