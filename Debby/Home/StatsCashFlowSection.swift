//
//  StatsCashFlowSection.swift
//  Debby
//
//  Created by Shox on 29/10/26.
//

import SwiftUI
import SwiftData
import Charts

struct StatsCashFlowSection: View {
    let entries: [Entry]
    let currency: Currency
    @Binding var period: StatsPeriod
    @Binding var rangeFrom: Date
    @Binding var rangeTo: Date

    @State private var selectedDay: Date?
    @State private var isShowingInfo = false
    @State private var isShowingDay = false

    private var flow: CashFlow {
        entries.cashFlow(
            in: currency,
            period: period,
            range: DayRange(from: rangeFrom, to: rangeTo)
        )
    }

    /// The day that matches the tapped bar, looked up fresh each time so it never
    /// points at an entry that has since been deleted.
    private var selectedFlowDay: CashFlowDay? {
        guard let selectedDay else { return nil }
        return flow.days.first { Calendar.current.isDate($0.day, inSameDayAs: selectedDay) }
    }

    var body: some View {
        let flow = flow

        VStack(alignment: .leading, spacing: Spacing.m) {
            header
            pills
            if period == .custom {
                rangePickers
            }
            summary(flow)

            if flow.operations == 0 {
                Text("No cash moved in \(currency.code) in this period.")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            } else {
                chart(flow)
                dayCard
            }
        }
        .onChange(of: period) { selectedDay = nil }
        .onChange(of: currency.code) { selectedDay = nil }
        .onChange(of: rangeFrom) { selectedDay = nil }
        .onChange(of: rangeTo) { selectedDay = nil }
        .sheet(isPresented: $isShowingDay) {
            DayEntriesSheet(
                title: selectedFlowDay?.day.formatted(.dateTime.weekday(.wide).day().month(.wide)) ?? "",
                entries: selectedFlowDay?.entries ?? []
            )
        }
    }

    // MARK: Header and period

    private var header: some View {
        HStack {
            Text("Cash flow")
                .font(.appTitle)
                .foregroundStyle(.textPrimary)
            Spacer()
            Button {
                isShowingInfo = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.title3)
                    .foregroundStyle(.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("About cash flow")
            .popover(isPresented: $isShowingInfo) {
                Text("Cash flow counts the money that changed hands, in the currency it was handed over in. The balances above are about who owes whom. An entry with a second currency moves cash in its first currency and changes the balance in its second.")
                    .font(.appBody)
                    .foregroundStyle(.textPrimary)
                    .padding(Spacing.m)
                    .frame(width: 300)
                    .presentationCompactAdaptation(.popover)
            }
        }
    }

    private var pills: some View {
        HStack(spacing: Spacing.s) {
            ForEach(StatsPeriod.allCases) { option in
                Button {
                    period = option
                } label: {
                    Text(option.title)
                        .font(.appBody)
                        .foregroundStyle(period == option ? Color.appBackground : Color.textPrimary)
                        .padding(.horizontal, Spacing.m)
                        .padding(.vertical, Spacing.s)
                        .background {
                            if period == option {
                                Capsule().fill(Color.textPrimary)
                            }
                        }
                        .overlay {
                            if period != option {
                                Capsule().stroke(Color.divider, lineWidth: 1)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
    }

    private var rangePickers: some View {
        VStack(spacing: Spacing.s) {
            HStack {
                Text("From")
                    .font(.appBody)
                    .foregroundStyle(.textPrimary)
                Spacer()
                DatePicker("From", selection: $rangeFrom, in: ...Date.now, displayedComponents: .date)
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
                DatePicker("To", selection: $rangeTo, in: ...Date.now, displayedComponents: .date)
                    .labelsHidden()
            }
        }
        .padding(Spacing.m)
        .background(.surface, in: RoundedRectangle(cornerRadius: Radius.l))
    }

    // MARK: Numbers

    private func summary(_ flow: CashFlow) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Net cash · \(periodLabel)")
                .font(.appCaption)
                .foregroundStyle(.textSecondary)

            BigAmount(
                text: signed(flow.net),
                currency: currency,
                color: flow.net > 0 ? .positive : .textPrimary
            )

            HStack(alignment: .top, spacing: Spacing.m) {
                figure("Received", compact(flow.received))
                figure("Gave", compact(flow.gave))
                figure("Operations", "\(flow.operations)")
            }
        }
    }

    private func figure(_ title: LocalizedStringKey, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
            Text(value)
                .font(.appHeadline)
                .foregroundStyle(.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Chart: received goes up, gave goes down

    private func chart(_ flow: CashFlow) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Chart {
                RuleMark(y: .value("Zero", 0))
                    .foregroundStyle(Color.divider)

                ForEach(flow.days) { day in
                    BarMark(
                        x: .value("Day", day.day, unit: .day),
                        y: .value("Received", major(day.received))
                    )
                    .foregroundStyle(Color.textPrimary)
                    .opacity(opacity(for: day))
                    .cornerRadius(3)

                    BarMark(
                        x: .value("Day", day.day, unit: .day),
                        y: .value("Gave", -major(day.gave))
                    )
                    .foregroundStyle(Color.textSecondary)
                    .opacity(opacity(for: day))
                    .cornerRadius(3)
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            select(at: location, proxy: proxy, geometry: geometry, in: flow)
                        }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                    AxisValueLabel {
                        if let number = value.as(Double.self) {
                            Text(abs(number).formatted(.number.notation(.compactName)))
                                .font(.appCaption)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 3)) { _ in
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                }
            }
            .frame(height: 180)

            HStack(spacing: Spacing.m) {
                legend("Received · up", color: .textPrimary)
                legend("Gave · down", color: .textSecondary)
            }
        }
    }

    private func legend(_ title: LocalizedStringKey, color: Color) -> some View {
        HStack(spacing: Spacing.xs) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 10, height: 10)
            Text(title)
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
        }
    }

    private func opacity(for day: CashFlowDay) -> Double {
        guard let selected = selectedFlowDay else { return 1 }
        return selected.id == day.id ? 1 : 0.3
    }
    
    /// Picks the day with bars that is closest to where the chart was tapped.
    /// Tapping the day that is already selected clears the selection.
    private func select(
        at location: CGPoint,
        proxy: ChartProxy,
        geometry: GeometryProxy,
        in flow: CashFlow
    ) {
        guard let plotFrame = proxy.plotFrame else { return }

        let x = location.x - geometry[plotFrame].origin.x
        guard let tapped: Date = proxy.value(atX: x) else { return }

        let nearest = flow.days.min {
            abs(middle(of: $0).timeIntervalSince(tapped)) < abs(middle(of: $1).timeIntervalSince(tapped))
        }
        guard let nearest else { return }

        if selectedFlowDay?.id == nearest.id {
            selectedDay = nil
        } else {
            selectedDay = nearest.day
        }
    }

    /// A bar covers its whole day, so compare against the middle of the day.
    private func middle(of day: CashFlowDay) -> Date {
        day.day.addingTimeInterval(12 * 3600)
    }

    // MARK: The tapped day

    @ViewBuilder
    private var dayCard: some View {
        if let day = selectedFlowDay {
            Button {
                isShowingDay = true
            } label: {
                HStack(spacing: Spacing.m) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(day.day.formatted(.dateTime.day().month(.abbreviated)))
                            .font(.appHeadline)
                            .foregroundStyle(.textPrimary)
                        HStack(spacing: Spacing.xs) {
                            Text(amounts(of: day))
                            Text("·")
                            Text("^[\(day.entries.count) entry](inflect: true)")
                        }
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                    }
                    Spacer(minLength: Spacing.s)
                    HStack(spacing: Spacing.xs) {
                        Text("View entries")
                        Image(systemName: "chevron.right")
                    }
                    .font(.appBody)
                    .foregroundStyle(.textSecondary)
                }
                .padding(Spacing.m)
                .background(.surface, in: RoundedRectangle(cornerRadius: Radius.m))
            }
            .buttonStyle(.plain)
        } else {
            Text("Tap a bar to see that day.")
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
        }
    }

    private func amounts(of day: CashFlowDay) -> String {
        var parts: [String] = []
        if day.received > 0 {
            parts.append(String(localized: "Received") + " " + compact(day.received))
        }
        if day.gave > 0 {
            parts.append(String(localized: "Gave") + " " + compact(day.gave))
        }
        return parts.joined(separator: " · ")
    }

    // MARK: Helpers

    private var periodLabel: String {
        switch period {
        case .today: return String(localized: "today")
        case .month: return String(localized: "this month")
        case .all: return String(localized: "all time")
        case .custom:
            let first = min(rangeFrom, rangeTo).formatted(.dateTime.day().month(.abbreviated))
            let last = max(rangeFrom, rangeTo).formatted(.dateTime.day().month(.abbreviated))
            return first == last ? first : "\(first) – \(last)"
        }
    }

    private func compact(_ minorUnits: Int) -> String {
        AmountParts(
            currency.formatted(minorUnits: minorUnits),
            fractionDigits: currency.fractionDigits
        ).compact
    }

    private func signed(_ minorUnits: Int) -> String {
        let amount = currency.formatted(minorUnits: abs(minorUnits))
        if minorUnits > 0 { return "+" + amount }
        if minorUnits < 0 { return "−" + amount }
        return amount
    }

    /// Minor units to the number the chart plots, e.g. 12050 cents -> 120.5.
    private func major(_ minorUnits: Int) -> Double {
        Double(minorUnits) / pow(10, Double(currency.fractionDigits))
    }
}

// MARK: - The entries of one day

private struct DayEntriesSheet: View {
    let title: String
    let entries: [Entry]

    @Environment(\.dismiss) private var dismiss
    @State private var editingEntry: Entry?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(entries) { entry in
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
                .padding(.horizontal, Spacing.m)
            }
            .background(.appBackground)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) { dismiss() }
                }
            }
            .sheet(item: $editingEntry) { AddEntryView(entry: $0) }
            // If the last entry of the day was deleted or moved, there is nothing left to show.
            .onChange(of: entries.isEmpty) {
                if entries.isEmpty { dismiss() }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    @Previewable @State var period = StatsPeriod.all
    @Previewable @State var from = Date.now
    @Previewable @State var to = Date.now

    NavigationStack {
        ScrollView {
            StatsCashFlowSection(
                entries: PreviewData.entries,
                currency: .eur,
                period: $period,
                rangeFrom: $from,
                rangeTo: $to
            )
            .padding(Spacing.m)
        }
    }
    .modelContainer(PreviewData.container)
}
