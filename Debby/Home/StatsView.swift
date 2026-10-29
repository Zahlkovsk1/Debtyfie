//
//  StatsView.swift
//  Debby
//
//  Created by Shox on 22/10/26.
//

import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query private var people: [Person]
    @Query private var entries: [Entry]
    @AppStorage("homeCurrencyCode") private var currencyCode = "EUR"
    @State private var selectedDay: Date?
    @State private var editingEntry: Entry?
    
    @State private var rangeFrom = Calendar.current.date(
        from: Calendar.current.dateComponents([.year, .month], from: .now)) ?? .now
    
    @State private var rangeTo = Date.now

    @AppStorage("statsPeriod") private var period = StatsPeriod.month

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

    private var flow: CashFlow {
        entries.cashFlow(
            in: currency,
            period: period,
            range: DayRange(from: rangeFrom, to: rangeTo)
        )
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
            .toolbar {
                           ToolbarItem(placement: .primaryAction) {
                               CurrencyChip(currency: currencyBinding, isProminent: true)
                           }
                       }
            .navigationDestination(for: Person.self) { PersonDetailView(person: $0) }
            .sheet(item: $editingEntry) { AddEntryView(entry: $0) }
                      .onChange(of: period) { selectedDay = nil }
                      .onChange(of: currencyCode) { selectedDay = nil }
                      .onChange(of: rangeFrom) { selectedDay = nil }
                    .onChange(of: rangeTo) { selectedDay = nil }
        }
    }

    // MARK: Section 1: Now

    private var nowSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Now")
                .font(.appTitle)
                .foregroundStyle(.textPrimary)

            HStack(spacing: Spacing.s) {
                StatTile(
                    title: "Owed to you",
                    value: currency.formatted(minorUnits: snapshot.owedToYou),
                    color: .positive
                )
                StatTile(
                    title: "You owe",
                    value: currency.formatted(minorUnits: snapshot.youOwe),
                    color: .negative
                )
            }

            StatRows {
                StatRow(title: "Net", value: signed(snapshot.net), color: color(for: snapshot.net))
                StatRow(title: "People with an open balance", value: "\(snapshot.openBalances)")
            }
        }
    }

    // MARK: Section 2: Cash flow

    private var cashFlowSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Cash flow")
                .font(.appTitle)
                .foregroundStyle(.textPrimary)

            Picker("Period", selection: $period) {
                ForEach(StatsPeriod.allCases) { period in
                    Text(period.title).tag(period)
                }
            }
            .pickerStyle(.segmented)
            
            if period == .custom {
                          rangePickers
                      }

            HStack(spacing: Spacing.s) {
                StatTile(title: "Received", value: currency.formatted(minorUnits: flow.received))
                StatTile(title: "Gave", value: currency.formatted(minorUnits: flow.gave))
            }

            StatRows {
                StatRow(title: "Net cash", value: signed(flow.net), color: color(for: flow.net))
                StatRow(title: "Operations", value: "\(flow.operations)")
            }

            if flow.operations == 0 {
                Text("No cash moved in \(currency.code) in this period.")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                    .padding(.top, Spacing.xs)
            } else {
                chart
            }

            Text("Cash flow counts the money that changed hands, in the currency it was handed over in. Balances are shown above.")
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
        }
    }
    
    private var rangePickers: some View {
        VStack(spacing: Spacing.s) {
            HStack {
                Text("From")
                    .font(.appBody)
                    .foregroundStyle(.textPrimary)
                Spacer()
                DatePicker(
                    "From",
                    selection: $rangeFrom,
                    in: ...Date.now,
                    displayedComponents: .date
                )
                .labelsHidden()
            }

            Rectangle()
                .fill(.divider)
                .frame(height: 1)

            HStack {
                Text("To")
                    .font(.appBody)
                    .foregroundStyle(.textPrimary)
                Spacer()
                DatePicker(
                    "To",
                    selection: $rangeTo,
                    in: ...Date.now,
                    displayedComponents: .date
                )
                .labelsHidden()
            }
        }
        .padding(Spacing.m)
        .background(.surface, in: RoundedRectangle(cornerRadius: Radius.l))
    }
    private var chart: some View {
        VStack(spacing: Spacing.s) {
            chartCard
            dayDetail
        }
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(spacing: Spacing.m) {
                legend("Received", color: .textPrimary)
                legend("Gave", color: .textSecondary)
            }

            Chart {
                ForEach(flow.days) { day in
                    BarMark(
                        x: .value("Day", day.day, unit: .day),
                        y: .value("Amount", major(day.received))
                    )
                    .foregroundStyle(Color.textPrimary)
                    .opacity(opacity(for: day))
                    .position(by: .value("Type", "received"))
                    .cornerRadius(4)

                    BarMark(
                        x: .value("Day", day.day, unit: .day),
                        y: .value("Amount", major(day.gave))
                    )
                    .foregroundStyle(Color.textSecondary)
                    .opacity(opacity(for: day))
                    .position(by: .value("Type", "gave"))
                    .cornerRadius(4)
                }
            }
            .chartXSelection(value: $selectedDay)
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                }
            }
            .frame(height: 200)
        }
        .padding(Spacing.m)
        .background(.surface, in: RoundedRectangle(cornerRadius: Radius.l))
    }

    /// The day with bars that matches the tapped position, if any.
    private var selectedFlowDay: CashFlowDay? {
        guard let selectedDay else { return nil }
        return flow.days.first { Calendar.current.isDate($0.day, inSameDayAs: selectedDay) }
    }

    /// Everything but the selected day is dimmed while a day is selected.
    private func opacity(for day: CashFlowDay) -> Double {
        guard let selected = selectedFlowDay else { return 1 }
        return selected.id == day.id ? 1 : 0.3
    }

    @ViewBuilder
    private var dayDetail: some View {
        if let day = selectedFlowDay {
            VStack(alignment: .leading, spacing: Spacing.s) {
                Text(day.day.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)

                HStack(spacing: Spacing.m) {
                    Text("Received \(currency.formatted(minorUnits: day.received))")
                    Text("Gave \(currency.formatted(minorUnits: day.gave))")
                }
                .font(.appCaption)
                .foregroundStyle(.textSecondary)

                VStack(spacing: 0) {
                    ForEach(day.entries) { entry in
                        Button {
                            editingEntry = entry
                        } label: {
                            HistoryRow(entry: entry)
                        }
                        .buttonStyle(.plain)

                        Rectangle()
                            .fill(.divider)
                            .frame(height: 1)
                    }
                }
            }
            .padding(Spacing.m)
            .background(.surface, in: RoundedRectangle(cornerRadius: Radius.l))
        } else {
            Text("Tap a bar to see that day's entries.")
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
        }
    }

    private func legend(_ title: LocalizedStringKey, color: Color) -> some View {
        HStack(spacing: Spacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
        }
    }

    // MARK: Helpers

    /// Minor units to the number the chart plots, e.g. 12050 cents -> 120.5.
    private func major(_ minorUnits: Int) -> Double {
        Double(minorUnits) / pow(10, Double(currency.fractionDigits))
    }

    private func signed(_ minorUnits: Int) -> String {
        let amount = currency.formatted(minorUnits: abs(minorUnits))
        if minorUnits > 0 { return "+" + amount }
        if minorUnits < 0 { return "−" + amount }
        return amount
    }

    private func color(for minorUnits: Int) -> Color {
        if minorUnits > 0 { return .positive }
        if minorUnits < 0 { return .negative }
        return .textPrimary
    }
}

// MARK: - Small building blocks

private struct StatTile: View {
    let title: LocalizedStringKey
    let value: String
    var color: Color = .textPrimary

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
            Text(value)
                .font(.appAmount)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.m)
        .background(.surface, in: RoundedRectangle(cornerRadius: Radius.l))
    }
}

private struct StatRows<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: Spacing.s) {
            content
        }
        .padding(Spacing.m)
        .background(.surface, in: RoundedRectangle(cornerRadius: Radius.l))
    }
}

private struct StatRow: View {
    let title: LocalizedStringKey
    let value: String
    var color: Color = .textPrimary

    var body: some View {
        HStack {
            Text(title)
                .font(.appBody)
                .foregroundStyle(.textSecondary)
            Spacer()
            Text(value)
                .font(.appHeadline)
                .foregroundStyle(color)
        }
    }
}

#Preview {
    StatsView()
        .modelContainer(PreviewData.container)
}
