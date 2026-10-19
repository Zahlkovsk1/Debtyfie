//
//  BalanceHeader.swift
//  Debby
//
//  Created by Shox on 19/10/26.
//

import SwiftUI

struct BalanceHeader: View {
    /// Net balance in minor units of `currency`. Positive: they owe you.
    let minorUnits: Int
    @Binding var currency: Currency

    private var caption: LocalizedStringKey {
        switch minorUnits {
        case 1...: "Owed to you"
        case ..<0: "You owe"
        default: "All settled"
        }
    }

    private var amountColor: Color {
        switch minorUnits {
        case 1...: .positive
        case ..<0: .negative
        default: .textPrimary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(caption)
                .font(.appCaption)
                .foregroundStyle(.textSecondary)

            Text(currency.formatted(minorUnits: abs(minorUnits)))
                .font(.appBalance)
                .foregroundStyle(amountColor)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            CurrencyChip(currency: $currency)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    @Previewable @State var eur = Currency.eur
    @Previewable @State var usd = Currency.usd
    @Previewable @State var rub = Currency.rub

    VStack(spacing: Spacing.xl) {
        BalanceHeader(minorUnits: 140_000, currency: $eur)
        BalanceHeader(minorUnits: -920_000, currency: $usd)
        BalanceHeader(minorUnits: 0, currency: $rub)
    }
    .padding(Spacing.m)
}
