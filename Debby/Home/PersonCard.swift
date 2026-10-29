//
//  PersonCard.swift
//  Debby
//
//  Created by Shox on 21/10/26.
//

import SwiftUI
import SwiftData

struct PersonCard: View {
    let person: Person
    let currency: Currency

    private var balance: Int { person.balances[currency] ?? 0 }

    /// How many other currencies have an open balance with this person.
    private var otherCurrencies: Int {
        person.balances.filter { $0.key != currency && $0.value != 0 }.count
    }

    private var amountText: String {
        if balance != 0 {
            return currency.formatted(minorUnits: abs(balance))
        }
        return person.entries.isEmpty ? "–" : String(localized: "Settled")
    }

    private var amountColor: Color {
        if balance > 0 { return .positive }
        if balance < 0 { return .negative }
        return .textSecondary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack(alignment: .top) {
                PersonAvatar(person: person, size: 48)
                Spacer(minLength: Spacing.s)
                if otherCurrencies > 0 {
                    moreCurrencies
                }
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 2) {
                Text(person.name)
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                    .lineLimit(1)

                Text(amountText)
                    .font(.appAmount)
                    .foregroundStyle(amountColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                status
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            }
        }
        .padding(Spacing.m)
        .frame(maxWidth: .infinity, minHeight: 168, alignment: .topLeading)
        .background(.surface, in: RoundedRectangle(cornerRadius: Radius.l))
        .contentShape(RoundedRectangle(cornerRadius: Radius.l))
    }

    @ViewBuilder
    private var status: some View {
        if balance > 0 {
            Text("owes you")
        } else if balance < 0 {
            Text("you owe")
        } else if person.entries.isEmpty {
            Text("No entries yet")
        }
    }

    private var moreCurrencies: some View {
        Text("+\(otherCurrencies)")
            .font(.appCaption)
            .foregroundStyle(.textPrimary)
            .padding(.horizontal, Spacing.s + Spacing.xs)
            .padding(.vertical, Spacing.xs)
            .background(.appBackground, in: Capsule())
            .accessibilityLabel(Text("\(otherCurrencies) more currencies"))
    }
}

#Preview {
    let columns = [
        GridItem(.flexible(), spacing: Spacing.m),
        GridItem(.flexible(), spacing: Spacing.m)
    ]
    ScrollView {
        LazyVGrid(columns: columns, spacing: Spacing.m) {
            ForEach(PreviewData.people) { person in
                PersonCard(person: person, currency: .eur)
            }
        }
        .padding(Spacing.m)
    }
    .modelContainer(PreviewData.container)
}
