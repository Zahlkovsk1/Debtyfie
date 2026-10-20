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
            Image(systemName: entry.direction == .gave ? "arrow.up.right" : "arrow.down.left")
                .font(.appHeadline)
                .foregroundStyle(.textPrimary)
                .frame(width: 44, height: 44)
                .background(.surface, in: Circle())

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
                Text(entry.currency.formatted(entry.amount))
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

    /// With the person's avatar and name on the home screen, or just the
    /// direction on the person's own screen, where the face would repeat.
    @ViewBuilder
    private var title: some View {
        if showsPerson {
            HStack(spacing: Spacing.s) {
                if let person = entry.person {
                    PersonAvatar(person: person, size: 28)
                }
                Text(entry.person?.name ?? "–")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
            }
        } else {
            Text(directionText)
                .font(.appHeadline)
                .foregroundStyle(.textPrimary)
        }
    }

    private var directionText: String {
        entry.direction == .gave ? String(localized: "You gave") : String(localized: "You received")
    }

    private var dateText: String {
        entry.date.formatted(.dateTime.day().month(.abbreviated).hour().minute())
    }

    private var subtitle: String {
        showsPerson ? "\(directionText) · \(dateText)" : dateText
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
