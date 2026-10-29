//
//  BigAmount.swift
//  Debby
//
//  Created by Shox on 29/10/26.
//

import SwiftUI

/// A large amount with the decimals and the currency symbol small and grey.
struct BigAmount: View {
    /// The already formatted text, for example "+62.500,00 ₽".
    let text: String
    let currency: Currency
    var color: Color = .textPrimary

    var body: some View {
        let parts = AmountParts(text, fractionDigits: currency.fractionDigits)

        HStack(alignment: .lastTextBaseline, spacing: 2) {
            Text(parts.head)
                .font(.appBalance)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(parts.fraction + parts.tail)
                .font(.appTitle)
                .foregroundStyle(.textSecondary)
                .lineLimit(1)
        }
    }
}

#Preview {
    BigAmount(text: "+62.500,00 ₽", currency: Currency(code: "RUB"), color: .positive)
        .padding(Spacing.m)
}
