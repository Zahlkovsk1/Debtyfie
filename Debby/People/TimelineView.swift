//
//  TimelineView.swift
//  Debby
//
//  Created by Shox on 21/10/26.
//

import SwiftUI
import SwiftData

struct TimelineView: View {
    let person: Person
    @AppStorage("homeCurrencyCode") private var currencyCode = "EUR"

    private var currency: Currency { Currency(code: currencyCode) }

    private var currencyBinding: Binding<Currency> {
        Binding(
            get: { Currency(code: currencyCode) },
            set: { currencyCode = $0.code }
        )
    }

    private var phases: [TimelinePhase] {
        person.entries.timelinePhases(in: currency)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.m) {
                CurrencyChip(currency: currencyBinding, isProminent: true)

                if phases.isEmpty {
                    ContentUnavailableView {
                        Label("No history yet", systemImage: "clock.arrow.circlepath")
                    } description: {
                        Text("There are no entries in \(currency.code) for \(person.name).")
                    }
                    .padding(.top, Spacing.xl)
                } else {
                    ForEach(phases) { phase in
                        PhaseCard(phase: phase, personName: person.name, currency: currency)
                    }
                }
            }
            .padding(.horizontal, Spacing.m)
            .padding(.top, Spacing.s)
            .padding(.bottom, Spacing.xl)
        }
        .background(.appBackground)
        .navigationTitle("Timeline with \(person.name)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - One phase

private struct PhaseCard: View {
    let phase: TimelinePhase
    let personName: String
    let currency: Currency

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            header
            progress
            events
        }
        .padding(Spacing.m)
        .background(.surface, in: RoundedRectangle(cornerRadius: Radius.l))
    }

    private var header: some View {
        HStack(alignment: .top, spacing: Spacing.s) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                title
                    .font(.appTitle)
                    .foregroundStyle(.textPrimary)
                Text(range)
                    .font(.appBody)
                    .foregroundStyle(.textSecondary)
            }
            Spacer(minLength: Spacing.s)
            statusBadge
        }
    }

    @ViewBuilder
    private var title: some View {
        switch phase.side {
        case .owedToYou: Text("\(personName) owes you")
        case .youOwe: Text("You owe \(personName)")
        }
    }

    private var range: String {
        let start = phase.start.formatted(.dateTime.day().month(.abbreviated))
        guard let end = phase.end else {
            return "\(start) – " + String(localized: "now")
        }
        let endText = end.formatted(.dateTime.day().month(.abbreviated))
        return start == endText ? start : "\(start) – \(endText)"
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch phase.status {
        case .open: badge("Open now", filled: true)
        case .settled: badge("Settled", filled: false)
        case .directionChanged: badge("Direction changed", filled: false)
        }
    }

    private func badge(_ text: LocalizedStringKey, filled: Bool) -> some View {
        Text(text)
            .font(.appCaption)
            .foregroundStyle(filled ? .appBackground : .textPrimary)
            .padding(.horizontal, Spacing.s + Spacing.xs)
            .padding(.vertical, Spacing.xs)
            .background(filled ? .textPrimary : .appBackground, in: Capsule())
    }

    // MARK: Progress

    private var progress: some View {
        VStack(spacing: Spacing.s) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Paid back")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                    Text(currency.formatted(minorUnits: phase.peak - phase.remaining))
                        .font(.appBody)
                        .foregroundStyle(.textPrimary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Still owed")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                    Text(currency.formatted(minorUnits: phase.remaining))
                        .font(.appBody)
                        .foregroundStyle(.textPrimary)
                }
            }

            Capsule()
                .fill(.divider)
                .frame(height: 8)
                .overlay(alignment: .leading) {
                    GeometryReader { geometry in
                        Capsule()
                            .fill(.textPrimary)
                            .frame(width: geometry.size.width * phase.progress)
                    }
                }
        }
    }

    // MARK: Events

    private var events: some View {
        // Newest first, like the history.
        let ordered = Array(phase.events.reversed())
        return VStack(spacing: 0) {
            ForEach(Array(ordered.enumerated()), id: \.element.id) { index, event in
                EventRow(
                    event: event,
                    personName: personName,
                    currency: currency,
                    isFirst: index == 0,
                    isLast: index == ordered.count - 1
                )
            }
        }
    }
}

// MARK: - One event on the line

private struct EventRow: View {
    let event: TimelineEvent
    let personName: String
    let currency: Currency
    let isFirst: Bool
    let isLast: Bool

    private let dotSize: CGFloat = 12

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            rail
            card
                .padding(.bottom, isLast ? 0 : Spacing.s)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    /// The dot and the line that joins it to the neighbouring events.
    private var rail: some View {
        let dotCentre = Spacing.m + dotSize / 2
        return ZStack(alignment: .top) {
            if !(isFirst && isLast) {
                Rectangle()
                    .fill(.divider)
                    .frame(width: 2)
                    .padding(.top, isFirst ? dotCentre : 0)
                    .frame(maxHeight: isLast ? dotCentre : .infinity, alignment: .top)
            }
            Circle()
                .fill(dotColor)
                .frame(width: dotSize, height: dotSize)
                .padding(.top, Spacing.m)
        }
        .frame(width: dotSize)
    }

    private var dotColor: Color {
        switch event.kind {
        case .settled: .positive
        case .flipped: .negative
        default: .textPrimary
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            title
                .font(.appHeadline)
                .foregroundStyle(.textPrimary)

            Text(detail)
                .font(.appBody)
                .foregroundStyle(.textSecondary)

            if !event.entry.note.isEmpty {
                Text(event.entry.note)
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(event.entry.date.formatted(.dateTime.day().month(.abbreviated).hour().minute()))
                    .font(.appCaption)
                    .foregroundStyle(.textPrimary)
                balanceText
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            }
            .padding(.top, Spacing.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.m)
        .background(.appBackground, in: RoundedRectangle(cornerRadius: Radius.m))
    }

    @ViewBuilder
    private var title: some View {
        switch event.kind {
        case .started:
            if event.balanceAfter > 0 {
                Text("\(personName) now owes you")
            } else {
                Text("You now owe \(personName)")
            }
        case .increased: Text("Balance increased")
        case .decreased: Text("Partial payment")
        case .settled: Text("Settled")
        case .flipped: Text("Balance changed direction")
        }
    }

    /// What was entered, in the currencies it was entered in.
    private var detail: String {
        let entry = event.entry
        let direction = entry.direction == .gave
            ? String(localized: "You gave")
            : String(localized: "You received")
        var text = "\(direction) \(entry.currency.formatted(entry.amount))"
        if let conversion = entry.conversion {
            text += " → \(conversion.currency.formatted(conversion.amount))"
        }
        return text
    }

    @ViewBuilder
    private var balanceText: some View {
        let amount = currency.formatted(minorUnits: abs(event.balanceAfter))
        if event.balanceAfter > 0 {
            Text("\(personName) owes you \(amount)")
        } else if event.balanceAfter < 0 {
            Text("You owe \(personName) \(amount)")
        } else {
            Text("All settled")
        }
    }
}

#Preview {
    NavigationStack {
        TimelineView(person: PreviewData.people[2])   // Baga
    }
    .modelContainer(PreviewData.container)
}
