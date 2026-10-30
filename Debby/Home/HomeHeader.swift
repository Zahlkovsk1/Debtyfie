//
//  HomeHeader.swift
//  Debby
//
//  Created by Shox on 29/10/26.
//

import SwiftUI

/// The top of the Main screen: label and currency on one line,
/// the big balance, and a one-line summary underneath.
struct HomeHeader: View {
    let snapshot: StatsSnapshot
    @Binding var currency: Currency

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack {
                title
                    .font(.appBody)
                    .foregroundStyle(.textSecondary)
                Spacer()
                CurrencyChip(currency: $currency, isProminent: true)
            }

            BigAmount(text: signedText, currency: currency)

            subtitle
                .font(.appBody)
                .foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Pieces

    @ViewBuilder
    private var title: some View {
        if snapshot.net > 0 {
            Text("Owed to you")
        } else if snapshot.net < 0 {
            Text("You owe")
        } else {
            Text("Balance")
        }
    }

    @ViewBuilder
    private var subtitle: some View {
        if snapshot.openBalances == 0 {
            Text("All settled")
        } else {
            Text("\(compact(snapshot.owedToYou)) owed to you · \(compact(snapshot.youOwe)) you owe · ^[\(snapshot.openBalances) person](inflect: true)")
        }
    }

    // MARK: Text helpers

    private func compact(_ minorUnits: Int) -> String {
        AmountParts(
            currency.formatted(minorUnits: minorUnits),
            fractionDigits: currency.fractionDigits
        ).compact
    }

    private var signedText: String {
        let amount = currency.formatted(minorUnits: abs(snapshot.net))
        return snapshot.net < 0 ? "−" + amount : amount
    }
}

#Preview {
    @Previewable @State var currency = Currency(code: "USD")

    VStack(spacing: Spacing.xl) {
        HomeHeader(
            snapshot: StatsSnapshot(owedToYou: 100_000, youOwe: 45_000, openBalances: 3),
            currency: $currency
        )
        HomeHeader(
            snapshot: StatsSnapshot(owedToYou: 20_000, youOwe: 90_000, openBalances: 2),
            currency: $currency
        )
        HomeHeader(
            snapshot: StatsSnapshot(owedToYou: 0, youOwe: 0, openBalances: 0),
            currency: $currency
        )
    }
    .padding(Spacing.m)
}
