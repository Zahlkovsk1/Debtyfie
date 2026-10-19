//
//  Entry.swift
//  Debby
//
//  Created by Shox on 18/10/26.
//

import Foundation
import SwiftData

/// Which way the money went, from YOUR point of view.
nonisolated enum Direction: String, Codable, Sendable {
    /// You gave money or goods to the person, so they owe you more
    case gave
    /// The person gave money to you, so they owe you less
    case received
}

/// The "counts as" part of an entry: what the balance changes by, and the rate you agreed.
nonisolated struct Conversion: Sendable {
    var currency: Currency   // e.g. EUR: the balance changes in this currency
    var amount: Decimal      // e.g. 9200: the final amount, the source of truth
    var rate: Decimal        // e.g. 0.92: kept as you typed it, for display
}

@Model
final class Entry {
    var id: UUID
    var date: Date           // when it happened (date and time)
    var createdAt: Date      // when it was typed into the app
    var direction: Direction
    var note: String

    // What physically changed hands. Stored as whole minor units (cents).
    var currencyCode: String
    var amountMinor: Int

    // Optional: what it counts as on the balance (nil = same as above)
    var counterCurrencyCode: String?
    var counterAmountMinor: Int?
    var rateText: String?    // the rate as text: "0.92" stays exactly "0.92"

    var person: Person?

    init(person: Person? = nil,
         date: Date = .now,
         direction: Direction,
         amount: Decimal,
         currency: Currency,
         conversion: Conversion? = nil,
         note: String = "") {
        self.id = UUID()
        self.date = date
        self.createdAt = .now
        self.direction = direction
        self.note = note
        self.currencyCode = currency.code
        self.amountMinor = currency.minorUnits(from: amount)
        self.counterCurrencyCode = conversion?.currency.code
        self.counterAmountMinor = conversion.map { $0.currency.minorUnits(from: $0.amount) }
        self.rateText = conversion.map { $0.rate.description }
        self.person = person
    }

    // MARK: Readable values (derived from the stored integers)

    var currency: Currency { Currency(code: currencyCode) }
    var amount: Decimal { currency.amount(fromMinorUnits: amountMinor) }

    var conversion: Conversion? {
        guard let code = counterCurrencyCode,
              let minor = counterAmountMinor,
              let text = rateText,
              let rate = Decimal(string: text) else { return nil }
        let counter = Currency(code: code)
        return Conversion(currency: counter,
                          amount: counter.amount(fromMinorUnits: minor),
                          rate: rate)
    }

    // MARK: The balance rule (Option A)

    /// The currency whose balance this entry changes.
    var ledgerCurrency: Currency {
        Currency(code: counterCurrencyCode ?? currencyCode)
    }

    /// How much the balance changes, in minor units.
    /// Positive means the person owes you more. Negative means you owe them more.
    var ledgerMinorUnits: Int {
        let size = counterAmountMinor ?? amountMinor
        return direction == .gave ? size : -size
    }
}
