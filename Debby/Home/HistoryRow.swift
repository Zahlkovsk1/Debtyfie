//
//  HistoryRow.swift
//  Debby
//
//  Created by Shox on 19/10/26.
//
import SwiftUI
import SwiftData

struct HistoryRow: View {
    let entry: Entry
    var showsPerson = true

    var body: some View {
        HStack(spacing: Spacing.m) {
            if showsPerson {
                avatar
            }

            VStack(alignment: .leading, spacing: 2) {
                title
                Text(subtitle)
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                if !entry.note.isEmpty {
                    Text(entry.note)
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: Spacing.s)

            VStack(alignment: .trailing, spacing: 2) {
                Text(amountText)
                    .font(.appAmount)
                    .foregroundStyle(.textPrimary)
                if let conversion = entry.conversion {
                    Text("→ \(conversion.currency.formatted(conversion.amount))")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }
            }
        }
        .padding(.vertical, Spacing.s)
        .contentShape(Rectangle())
    }

    // MARK: Pieces

    /// The person's own avatar, shown on the home screen only.
    @ViewBuilder
    private var avatar: some View {
        if let person = entry.person {
            PersonAvatar(person: person, size: 44)
        } else {
            Circle()
                .fill(Color.surface)
                .frame(width: 44, height: 44)
        }
    }

    /// The person's name on the home screen, or just the direction on the
    /// person's own screen, where their face would repeat on every row.
    @ViewBuilder
    private var title: some View {
        if showsPerson {
            Text(entry.person?.name ?? "–")
                .font(.appHeadline)
                .foregroundStyle(.textPrimary)
        } else {
            Text(directionText)
                .font(.appHeadline)
                .foregroundStyle(.textPrimary)
        }
    }

    // MARK: Text

    /// "+200,00 $" when you received, "−500,00 $" when you gave.
    private var amountText: String {
        let amount = entry.currency.formatted(entry.amount)
        return entry.direction == .gave ? "−" + amount : "+" + amount
    }

    private var directionText: String {
        entry.direction == .gave ? String(localized: "You gave") : String(localized: "You received")
    }

    private var timeText: String {
        entry.date.formatted(date: .omitted, time: .shortened)
    }

    private var subtitle: String {
        showsPerson ? "\(directionText) · \(timeText)" : timeText
    }
}

#Preview {
    VStack(spacing: 0) {
        ForEach(PreviewData.entries) { entry in
            HistoryRow(entry: entry)
            Divider()
        }
    }
    .padding(.horizontal, Spacing.m)
    .modelContainer(PreviewData.container)
}
