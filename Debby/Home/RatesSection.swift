//
//  RatesSection.swift
//  Debby
//
//  Created by Shox on 29/10/26.
//
import SwiftUI
import SwiftData

struct RatesSection: View {
    let entries: [Entry]
    let period: StatsPeriod
    let range: DayRange

    /// The ids of the pairs that are currently open.
    @State private var expanded: Set<String> = []

    private var summaries: [RateSummary] {
        entries.rateSummaries(period: period, range: range)
    }

    var body: some View {
        let items = summaries

        // No exchanges in this period: the section doesn't appear at all.
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.s) {
                Text("Exchange rates")
                    .font(.appTitle)
                    .foregroundStyle(.textPrimary)

                VStack(spacing: 0) {
                    ForEach(items) { summary in
                        RateRow(summary: summary, isExpanded: expanded.contains(summary.id)) {
                            withAnimation(.snappy) { toggle(summary.id) }
                        }

                        Rectangle()
                            .fill(.divider)
                            .frame(height: 1)
                    }
                }
            }
        }
    }

    private func toggle(_ id: String) {
        if expanded.contains(id) {
            expanded.remove(id)
        } else {
            expanded.insert(id)
        }
    }
}

// MARK: - One currency pair

private struct RateRow: View {
    let summary: RateSummary
    let isExpanded: Bool
    let onTap: () -> Void

    private var base: Currency { summary.pair.base }
    private var quote: Currency { summary.pair.quote }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Button(action: onTap) {
                HStack(spacing: Spacing.m) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(base.code) → \(quote.code)")
                            .font(.appHeadline)
                            .foregroundStyle(.textPrimary)
                        HStack(spacing: Spacing.xs) {
                            Text("Average")
                            Text("·")
                            Text("^[\(summary.operations) exchange](inflect: true)")
                        }
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                    }

                    Spacer(minLength: Spacing.s)

                    Text(rateText(summary.average))
                        .font(.appHeadline)
                        .foregroundStyle(.textPrimary)
                        .lineLimit(1)

                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.vertical, Spacing.s)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                details
                    .padding(.bottom, Spacing.s)
                    .transition(.opacity)
            }
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack(alignment: .top, spacing: Spacing.m) {
                figure("Latest", summary.latest)
                figure("Lowest", summary.lowest)
                figure("Highest", summary.highest)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Exchanged")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                Text("\(base.formatted(minorUnits: summary.baseVolume)) ⇄ \(quote.formatted(minorUnits: summary.quoteVolume))")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Text("1 \(base.code) = rate in \(quote.code). The average is weighted by amount.")
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
        }
    }

    private func figure(_ title: LocalizedStringKey, _ rate: Decimal) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
            Text(rateText(rate))
                .font(.appHeadline)
                .foregroundStyle(.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Big rates (12.650) need fewer decimals than small ones (1,0870).
    private func rateText(_ rate: Decimal) -> String {
        let digits: ClosedRange<Int>
        switch rate {
        case 1_000...: digits = 0...2
        case 10...: digits = 0...3
        default: digits = 0...4
        }
        return rate.formatted(.number.precision(.fractionLength(digits)))
    }
}

#Preview {
    ScrollView {
        RatesSection(
            entries: PreviewData.entries,
            period: .all,
            range: DayRange(from: .now, to: .now)
        )
        .padding(Spacing.m)
    }
    .modelContainer(PreviewData.container)
}
