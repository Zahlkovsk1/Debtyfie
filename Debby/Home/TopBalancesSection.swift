//
//  TopBalancesSection.swift
//  Debby
//
//  Created by Shox on 23/10/26.
//

import SwiftUI
import SwiftData

struct TopBalancesSection: View {
    let people: [Person]
    let currency: Currency

    @State private var side = OwedSide.owedToYou

    private var rows: [OwedSummary.Row] {
        people.topBalances(side, in: currency)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Biggest balances")
                .font(.appTitle)
                .foregroundStyle(.textPrimary)

            Picker("Side", selection: $side) {
                Text("Owed to you").tag(OwedSide.owedToYou)
                Text("You owe").tag(OwedSide.youOwe)
            }
            .pickerStyle(.segmented)

            if rows.isEmpty {
                emptyText
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                    .padding(.top, Spacing.xs)
            } else {
                let largest = max(rows.first?.minorUnits ?? 1, 1)
                VStack(spacing: Spacing.m) {
                    ForEach(rows) { row in
                        NavigationLink(value: row.person) {
                            rowView(row, largest: largest)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Spacing.m)
                .background(.surface, in: RoundedRectangle(cornerRadius: Radius.l))
            }
        }
    }

    @ViewBuilder
    private var emptyText: some View {
        switch side {
        case .owedToYou: Text("Nobody owes you in \(currency.code).")
        case .youOwe: Text("You owe nobody in \(currency.code).")
        }
    }

    private func rowView(_ row: OwedSummary.Row, largest: Int) -> some View {
        HStack(spacing: Spacing.m) {
            PersonAvatar(person: row.person, size: 36)

            VStack(spacing: 6) {
                HStack {
                    Text(row.person.name)
                        .font(.appBody)
                        .foregroundStyle(.textPrimary)
                        .lineLimit(1)
                    Spacer(minLength: Spacing.s)
                    Text(currency.formatted(minorUnits: row.minorUnits))
                        .font(.appHeadline)
                        .foregroundStyle(side == .owedToYou ? Color.positive : Color.negative)
                        .lineLimit(1)
                }

                Capsule()
                    .fill(.divider)
                    .frame(height: 6)
                    .overlay(alignment: .leading) {
                        GeometryReader { geometry in
                            Capsule()
                                .fill(.textPrimary)
                                .frame(width: geometry.size.width * Double(row.minorUnits) / Double(largest))
                        }
                    }
            }
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            TopBalancesSection(people: PreviewData.people, currency: .eur)
                .padding(Spacing.m)
        }
        .navigationDestination(for: Person.self) { PersonDetailView(person: $0) }
    }
    .modelContainer(PreviewData.container)
}
