//
//  StatsOverviewSection.swift
//  Debby
//
//  Created by Shox on 29/10/26.
//

import SwiftUI

struct StatsOverviewSection: View {
    let snapshot: StatsSnapshot
    let currency: Currency

    private var total: Int { snapshot.owedToYou + snapshot.youOwe }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Open balance")
                .font(.appCaption)
                .foregroundStyle(.textSecondary)

            BigAmount(text: signedText, currency: currency, color: netColor)

            subtitle
                .font(.appBody)
                .foregroundStyle(.textSecondary)

            if total > 0 {
                proportionBar
                    .padding(.top, Spacing.xs)

                HStack(alignment: .top) {
                    legend("Owed to you", amount: "+" + compact(snapshot.owedToYou),
                           dot: Color.positive, color: Color.positive, alignment: .leading)
                    Spacer()
                    legend("You owe", amount: "−" + compact(snapshot.youOwe),
                           dot: Color.textPrimary, color: Color.textPrimary, alignment: .trailing)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Pieces

 

    @ViewBuilder
    private var subtitle: some View {
        if snapshot.openBalances == 0 {
            Text("All settled")
        } else if snapshot.net < 0 {
            Text("You owe more than you're owed · ^[\(snapshot.openBalances) person](inflect: true)")
        } else if snapshot.net > 0 {
            Text("You're owed more than you owe · ^[\(snapshot.openBalances) person](inflect: true)")
        } else {
            Text("Evenly balanced · ^[\(snapshot.openBalances) person](inflect: true)")
        }
    }

    private var proportionBar: some View {
        GeometryReader { geometry in
            let gap: CGFloat = (snapshot.owedToYou > 0 && snapshot.youOwe > 0) ? 4 : 0
            let available = geometry.size.width - gap

            HStack(spacing: gap) {
                if snapshot.owedToYou > 0 {
                    Capsule()
                        .fill(Color.positive)
                        .frame(width: available * Double(snapshot.owedToYou) / Double(total))
                }
                if snapshot.youOwe > 0 {
                    Capsule()
                        .fill(Color.textPrimary)
                        .frame(width: available * Double(snapshot.youOwe) / Double(total))
                }
            }
        }
        .frame(height: 8)
    }

    private func legend(
        _ title: LocalizedStringKey, amount: String,
        dot: Color, color: Color, alignment: HorizontalAlignment
    ) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            HStack(spacing: Spacing.xs) {
                Circle()
                    .fill(dot)
                    .frame(width: 8, height: 8)
                Text(title)
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            }
            Text(amount)
                .font(.appHeadline)
                .foregroundStyle(color)
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
        if snapshot.net > 0 { return "+" + amount }
        if snapshot.net < 0 { return "−" + amount }
        return amount
    }

    private var netColor: Color {
        snapshot.net > 0 ? .positive : .textPrimary
    }
}

#Preview {
    VStack(spacing: Spacing.xl) {
        StatsOverviewSection(
            snapshot: StatsSnapshot(owedToYou: 900_000, youOwe: 7_650_000, openBalances: 2),
            currency: Currency(code: "RUB")
        )
        StatsOverviewSection(
            snapshot: StatsSnapshot(owedToYou: 0, youOwe: 0, openBalances: 0),
            currency: .eur
        )
    }
    .padding(Spacing.m)
}
