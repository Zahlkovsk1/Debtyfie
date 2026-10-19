//
//  Balances.swift
//  Debby
//
//  Created by Shox on 19/10/26.
//

import Foundation
import Foundation

extension Sequence where Element == Entry {
    /// Net balance per currency, in minor units.
    /// Positive: they owe you. Negative: you owe them.
    func balancesByCurrency() -> [Currency: Int] {
        var result: [Currency: Int] = [:]
        for entry in self {
            result[entry.ledgerCurrency, default: 0] += entry.ledgerMinorUnits
        }
        return result
    }
}

extension Person {
    var balances: [Currency: Int] { entries.balancesByCurrency() }

    /// The balance in one currency, as a readable amount.
    func balance(in currency: Currency) -> Decimal {
        currency.amount(fromMinorUnits: balances[currency] ?? 0)
    }
}

extension Sequence where Element == Person {
    /// Everyone's balances added up, per currency, in minor units.
    func totalBalances() -> [Currency: Int] {
        var total: [Currency: Int] = [:]
        for person in self {
            for (currency, minor) in person.balances {
                total[currency, default: 0] += minor
            }
        }
        return total
    }
}
