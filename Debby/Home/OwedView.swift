//
//  OwedView.swift
//  Debby
//
//  Created by Shox on 21/10/26.
//

import SwiftUI
import SwiftData

struct OwedView: View {
    private enum Sort: CaseIterable, Identifiable {
        case largest, recent, name

        var id: Self { self }

        var title: LocalizedStringKey {
            switch self {
            case .largest: "Largest"
            case .recent: "Recent"
            case .name: "Name"
            }
        }
    }

    @Query private var people: [Person]
    @AppStorage("homeCurrencyCode") private var currencyCode = "EUR"

    @State private var side = OwedSide.owedToYou
    @State private var sort = Sort.largest

    private var currency: Currency { Currency(code: currencyCode) }

    private var currencyBinding: Binding<Currency> {
        Binding(
            get: { Currency(code: currencyCode) },
            set: { currencyCode = $0.code }
        )
    }

    private var summary: OwedSummary {
        people.owedSummary(side, in: currency)
    }

    private var sortedRows: [OwedSummary.Row] {
        switch sort {
        case .largest:
            summary.rows.sorted { $0.minorUnits > $1.minorUnits }
        case .recent:
            summary.rows.sorted { $0.person.lastActivity > $1.person.lastActivity }
        case .name:
            summary.rows.sorted {
                $0.person.name.localizedStandardCompare($1.person.name) == .orderedAscending
            }
        }
    }

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.m),
        GridItem(.flexible(), spacing: Spacing.m)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.m) {
                Picker("Side", selection: $side) {
                    Text("Owed to you").tag(OwedSide.owedToYou)
                    Text("You owe").tag(OwedSide.youOwe)
                }
                .pickerStyle(.segmented)

                totalCard
                listHeader

                if sortedRows.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(columns: columns, spacing: Spacing.m) {
                        ForEach(sortedRows) { row in
                            card(for: row)
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.m)
            .padding(.top, Spacing.s)
            .padding(.bottom, Spacing.xl)
        }
        .background(.appBackground)
        .navigationTitle("Owed")
        .navigationDestination(for: Person.self) { PersonDetailView(person: $0) }
    }

    // MARK: Pieces

    private var totalCard: some View {
        VStack(spacing: Spacing.s) {
            Text(currency.formatted(minorUnits: summary.total))
                .font(.appBalance)
                .foregroundStyle(.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            caption

            CurrencyChip(currency: currencyBinding, isProminent: true)
                .padding(.top, Spacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.m)
        .background(.surface, in: RoundedRectangle(cornerRadius: Radius.l))
    }

    @ViewBuilder
    private var caption: some View {
        switch side {
        case .owedToYou:
            Text("Total owed to you in \(currency.code)")
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
        case .youOwe:
            Text("Total you owe in \(currency.code)")
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
        }
    }

    private var listHeader: some View {
        HStack {
            Text("^[\(sortedRows.count) balance](inflect: true)")
                .font(.appBody)
                .foregroundStyle(.textSecondary)

            Spacer()

            Menu {
                Picker("Sort", selection: $sort) {
                    ForEach(Sort.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
            } label: {
                HStack(spacing: Spacing.xs) {
                    Text("Sort:")
                        .foregroundStyle(.textSecondary)
                    Text(sort.title)
                        .foregroundStyle(.textPrimary)
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.textPrimary)
                }
                .font(.appBody)
            }
        }
        .padding(.top, Spacing.s)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label(
                side == .owedToYou ? "Nobody owes you" : "You owe nobody",
                systemImage: "checkmark.circle"
            )
        } description: {
            Text("No open balances in \(currency.code).")
        }
        .padding(.top, Spacing.xl)
    }

    private func card(for row: OwedSummary.Row) -> some View {
        NavigationLink(value: row.person) {
            VStack(spacing: Spacing.s) {
                PersonAvatar(person: row.person, size: 64)

                Text(row.person.name)
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                    .lineLimit(1)

                amountText(for: row)
                    .font(.appBody)
                    .foregroundStyle(.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text("Last activity \(row.person.lastActivity.formatted(.dateTime.day().month(.abbreviated)))")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.m)
            .background(.surface, in: RoundedRectangle(cornerRadius: Radius.l))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func amountText(for row: OwedSummary.Row) -> some View {
        let amount = currency.formatted(minorUnits: row.minorUnits)
        switch side {
        case .owedToYou: Text("Owes you \(amount)")
        case .youOwe: Text("You owe \(amount)")
        }
    }
}

#Preview {
    NavigationStack {
        OwedView()
    }
    .modelContainer(PreviewData.container)
}
