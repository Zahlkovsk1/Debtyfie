//
//  CardRow.swift
//  Debby
//
//  Created by Shox on 19/10/26.
//

import SwiftUI

/// A small pill with the network or bank name. Official logos can replace this later.
struct CardBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .foregroundStyle(.textPrimary)
            .padding(.horizontal, Spacing.s)
            .padding(.vertical, 3)
            .background(.appBackground, in: Capsule())
    }
}

struct CardRow: View {
    let number: String            // digits only
    var holderName: String = ""
    var bank: Bank?
    var onDelete: (() -> Void)?

    @State private var justCopied = false

    private var network: CardNetwork? { CardNetwork(number: number) }

    var body: some View {
        HStack(spacing: Spacing.m) {
            VStack(alignment: .leading, spacing: Spacing.s) {
                if network != nil || bank != nil {
                    HStack(spacing: Spacing.s) {
                        if let network { CardBadge(text: network.displayName) }
                        if let bank { CardBadge(text: bank.displayName) }
                    }
                }
                Text(CardNetwork.grouped(number))
                    .font(.appAmount)
                    .foregroundStyle(.textPrimary)
                if !holderName.isEmpty {
                    Text(holderName)
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }
            }

            Spacer(minLength: Spacing.s)

            HStack(spacing: Spacing.m) {
                Button(action: copy) {
                    Image(systemName: justCopied ? "checkmark" : "doc.on.doc")
                }
                .accessibilityLabel("Copy card number")

                if let onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                    }
                    .accessibilityLabel("Remove card")
                }
            }
            .font(.appBody)
            .foregroundStyle(.textSecondary)
            .buttonStyle(.plain)
        }
        .fieldStyle()
        .sensoryFeedback(.success, trigger: justCopied) { _, new in new }
    }

    private func copy() {
        UIPasteboard.general.string = number
        justCopied = true
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            justCopied = false
        }
    }
}

#Preview {
    VStack(spacing: Spacing.m) {
        CardRow(number: "8600123456789012", holderName: "ALI KARIMOV")
        CardRow(number: "2200123456789012", holderName: "ALI KARIMOV", bank: .sber) {}
        CardRow(number: "4111111111111111", bank: .tbank)
        CardRow(number: "1234567890123456")
    }
    .padding(Spacing.m)
}
