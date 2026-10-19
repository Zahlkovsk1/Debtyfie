//
//  ContactRow.swift
//  Debby
//
//  Created by Shox on 19/10/26.
//

import SwiftUI

/// An icon, a small label, and a value. Tapping opens the link, if there is one.
struct ContactRow: View {
    let icon: String
    let title: LocalizedStringKey
    let value: String
    var url: URL?

    var body: some View {
        let content = HStack(spacing: Spacing.m) {
            Image(systemName: icon)
                .font(.appHeadline)
                .foregroundStyle(.textPrimary)
                .frame(width: 36, height: 36)
                .background(.appBackground, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                Text(value)
                    .font(.appBody)
                    .foregroundStyle(.textPrimary)
            }

            Spacer(minLength: Spacing.s)

            if url != nil {
                Image(systemName: "arrow.up.right")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            }
        }
        .fieldStyle()

        if let url {
            Link(destination: url) { content }
                .buttonStyle(.plain)
        } else {
            content
        }
    }
}

#Preview {
    VStack(spacing: Spacing.s) {
        ContactRow(icon: "phone", title: "Phone", value: "+998 901 234 567",
                   url: URL(string: "tel:+998901234567"))
        ContactRow(icon: "paperplane", title: "Telegram", value: "@ali_karimov",
                   url: URL(string: "https://t.me/ali_karimov"))
    }
    .padding(Spacing.m)
}
