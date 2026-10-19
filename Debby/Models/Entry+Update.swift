//
//  Entry+Update.swift
//  Debby
//
//  Created by Shox on 19/10/26.
//

import Foundation

extension Entry {
    /// Rewrites every field of the entry, the same way `init` fills them in.
    func update(
        person: Person,
        date: Date,
        direction: Direction,
        amount: Decimal,
        currency: Currency,
        conversion: Conversion?,
        note: String
    ) {
        self.person = person
        self.date = date
        self.direction = direction
        self.note = note
        self.currencyCode = currency.code
        self.amountMinor = currency.minorUnits(from: amount)
        self.counterCurrencyCode = conversion?.currency.code
        self.counterAmountMinor = conversion.map { $0.currency.minorUnits(from: $0.amount) }
        self.rateText = conversion.map { $0.rate.description }
    }
}
