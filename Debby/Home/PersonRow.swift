//
//  PersonRow.swift
//  Debby
//
//  Created by Shox on 19/10/26.
//

import SwiftUI
import SwiftData

struct PersonRow: View {
    let person: Person
    let currency: Currency

    var body: some View {
        HStack(spacing: Spacing.m) {
            PersonAvatar(person: person)

            VStack(alignment: .leading, spacing: 2) {
                Text(person.name)
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Text(person.lastActivity, format: .relative(presentation: .named))
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            }

            Spacer(minLength: Spacing.s)

            balance
        }
        .padding(.vertical, Spacing.s)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var balance: some View {
        if let minor = person.balances[currency] {
            if minor == 0 {
                Text("Settled")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            } else {
                let tint: Color = minor > 0 ? .positive : .negative
                VStack(alignment: .trailing, spacing: 2) {
                    Text(currency.formatted(minorUnits: abs(minor)))
                        .font(.appAmount)
                        .foregroundStyle(tint)
                    if minor > 0 {
                        Text("owes you").font(.appCaption).foregroundStyle(.textSecondary)
                    } else {
                        Text("you owe").font(.appCaption).foregroundStyle(.textSecondary)
                    }
                }
            }
        } else {
            Text("–")
                .font(.appBody)
                .foregroundStyle(.textSecondary)
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        ForEach(PreviewData.people) { person in
            PersonRow(person: person, currency: .eur)
            Divider()
        }
    }
    .padding(.horizontal, Spacing.m)
    .modelContainer(PreviewData.container)
}
