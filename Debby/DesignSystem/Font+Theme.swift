//
//  Font+Theme.swift
//  Debby
//
//  Created by Shox on 18/10/26.
//

import Foundation
import SwiftUI

extension Font {
    /// The big hero number — total balance on the home screen
    static let appBalance = Font.system(size: 44, weight: .bold).monospacedDigit()

    /// Screen titles and the person's name on their detail screen
    static let appTitle = Font.system(.title2, weight: .bold)

    /// Names in lists, section headers
    static let appHeadline = Font.system(.headline, weight: .semibold)

    /// Regular text
    static let appBody = Font.system(.body)

    /// Dates, "owes you" labels, notes
    static let appCaption = Font.system(.footnote)

    /// Money amounts in lists and history rows
    static let appAmount = Font.system(.body, weight: .semibold).monospacedDigit()
}

#Preview {
    VStack(alignment: .leading, spacing: 24) {
        VStack(alignment: .leading, spacing: 4) {
            Text("Total balance")
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
            Text("900,00 €")
                .font(.appBalance)
                .foregroundStyle(.textPrimary)
            Text("Amount owed to you")
                .font(.appBody)
                .foregroundStyle(.textSecondary)
        }

        Rectangle().fill(.divider).frame(height: 1)

        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Gafur").font(.appHeadline)
                Text("Loan started · Friday").font(.appCaption)
                    .foregroundStyle(.textSecondary)
            }
            Spacer()
            Text("1.400,00 €").font(.appAmount).foregroundStyle(.positive)
        }

        // Digit-width test: both lines should be exactly equally wide
        VStack(alignment: .trailing, spacing: 4) {
            Text("111,11 €").font(.appAmount)
            Text("888,88 €").font(.appAmount)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
    .foregroundStyle(.textPrimary)
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(.appBackground)
}
