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

    var body: some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: entry.direction == .gave ? "arrow.up.right" : "arrow.down.left")
                .font(.appHeadline)
                .foregroundStyle(.textPrimary)
                .frame(width: 44, height: 44)
                .background(.surface, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.person?.name ?? "–")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
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
    }

    private var subtitle: String {
        let who = entry.direction == .gave ? String(localized: "You gave") : String(localized: "You received")
        let when = entry.date.formatted(.dateTime.day().month(.abbreviated).hour().minute())
        return "\(who) · \(when)"
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
