//
//  OwedView.swift
//  Debby
//
//  Created by Shox on 21/10/26.
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
    /// Only used to decide which chip comes first. Tapping a chip here never changes it.
    @AppStorage("homeCurrencyCode") private var homeCurrencyCode = "EUR"

    @State private var side = OwedSide.owedToYou
    @State private var sort = Sort.largest
    /// The chip the user tapped last. nil until they tap one.
    @State private var chosenCurrency: Currency?

    /// The chips for the side being looked at.
    private var options: [OwedCurrency] {
        people.owedCurrencies(side, preferred: Currency(code: homeCurrencyCode))
    }

    /// The chosen currency if this side still has it, otherwise the first chip.
    private var currency: Currency? {
        OwedCurrency.resolve(selected: chosenCurrency, in: options)
    }

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.m),
        GridItem(.flexible(), spacing: Spacing.m)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.m) {
                SegmentedTabs(selection: $side, options: [.owedToYou, .youOwe]) { side -> LocalizedStringKey in
                    switch side {
                    case .owedToYou: "Owed to you"
                    case .youOwe: "You owe"
                    }
                }

                if let currency {
                    let summary = people.owedSummary(side, in: currency)

                    totalHeader(currency: currency, summary: summary)

                    CurrencyFilterChips(options: options, selected: currency) {
                        chosenCurrency = $0
                    }

                    listHeader

                    LazyVGrid(columns: columns, spacing: Spacing.m) {
                        ForEach(sortedRows(of: summary)) { row in
                            card(for: row, in: currency)
                        }
                    }
                } else {
                    emptyState
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

    private func totalHeader(currency: Currency, summary: OwedSummary) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            caption(for: currency)
                .font(.appBody)
                .foregroundStyle(.textSecondary)

            BigAmount(text: currency.formatted(minorUnits: summary.total), currency: currency)

            Text("^[\(summary.rows.count) person](inflect: true)")
                .font(.appBody)
                .foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Spacing.s)
    }

    @ViewBuilder
    private func caption(for currency: Currency) -> some View {
        switch side {
        case .owedToYou:
            Text("Total owed to you in \(currency.code)")
        case .youOwe:
            Text("Total you owe in \(currency.code)")
        }
    }

    private var listHeader: some View {
        HStack {
            Text("People")
                .font(.appTitle)
                .foregroundStyle(.textPrimary)

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
            Text("No open balances.")
        }
        .padding(.top, Spacing.xl)
    }

    private func sortedRows(of summary: OwedSummary) -> [OwedSummary.Row] {
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

    private func card(for row: OwedSummary.Row, in currency: Currency) -> some View {
        NavigationLink(value: row.person) {
            VStack(spacing: Spacing.s) {
                PersonAvatar(person: row.person, size: 64)

                Text(row.person.name)
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                    .lineLimit(1)

                amountText(for: row, in: currency)
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
    private func amountText(for row: OwedSummary.Row, in currency: Currency) -> some View {
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
