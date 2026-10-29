//
//  StatsView.swift
//  Debby
//
//  Created by Shox on 22/10/26.
//

import SwiftUI
import SwiftData

struct StatsView: View {
    @Query private var people: [Person]
    @Query private var entries: [Entry]
    @AppStorage("homeCurrencyCode") private var currencyCode = "EUR"
    @AppStorage("statsPeriod") private var period = StatsPeriod.month

    /// The dates for the "Range" period: first day of this month until today.
    @State private var rangeFrom = Calendar.current.date(
        from: Calendar.current.dateComponents([.year, .month], from: .now)
    ) ?? .now
    @State private var rangeTo = Date.now

    private var currency: Currency { Currency(code: currencyCode) }

    private var currencyBinding: Binding<Currency> {
        Binding(
            get: { Currency(code: currencyCode) },
            set: { currencyCode = $0.code }
        )
    }

    private var snapshot: StatsSnapshot {
        people.statsSnapshot(in: currency)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if entries.isEmpty {
                    ContentUnavailableView {
                        Label("No numbers yet", systemImage: "chart.bar")
                    } description: {
                        Text("Statistics appear as soon as you add the first entry.")
                    }
                    .padding(.top, Spacing.xl)
                } else {
                    VStack(alignment: .leading, spacing: Spacing.l) {
                        StatsOverviewSection(snapshot: snapshot, currency: currency)

                        StatsPeopleSection(people: people, currency: currency)

                        // A light band that separates "who owes what" from "money movement".
                        Rectangle()
                            .fill(.surface)
                            .frame(height: 8)
                            .padding(.horizontal, -Spacing.m)

                        StatsCashFlowSection(
                            entries: entries,
                            currency: currency,
                            period: $period,
                            rangeFrom: $rangeFrom,
                            rangeTo: $rangeTo
                        )

                        RatesSection(
                            entries: entries,
                            period: period,
                            range: DayRange(from: rangeFrom, to: rangeTo)
                        )
                    }
                    .padding(.horizontal, Spacing.m)
                    .padding(.top, Spacing.s)
                    .padding(.bottom, Spacing.xl)
                }
            }
            .background(.appBackground)
            .navigationTitle("Statistics")
            .navigationDestination(for: Person.self) { PersonDetailView(person: $0) }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    CurrencyChip(currency: currencyBinding, isProminent: true)
                }
            }
        }
    }
}

#Preview {
    StatsView()
        .modelContainer(PreviewData.container)
}
