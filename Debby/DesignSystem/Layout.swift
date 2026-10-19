//
//  Layout.swift
//  Debby
//
//  Created by Shox on 18/10/26.
//


import SwiftUI

/// Spacing scale: every gap in the app is one of these.
enum Spacing {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 16
    static let l: CGFloat = 24
    static let xl: CGFloat = 32
}

/// Corner radii: small for chips, medium for cards, large for sheets.
enum Radius {
    static let s: CGFloat = 10
    static let m: CGFloat = 16
    static let l: CGFloat = 24
}

#Preview {
    VStack(alignment: .leading, spacing: Spacing.m) {
        Text("Gafur")
            .font(.appHeadline)
        Text("1.400,00 €")
            .font(.appAmount)
            .foregroundStyle(.positive)
    }
    .foregroundStyle(.textPrimary)
    .padding(Spacing.m)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.surface, in: .rect(cornerRadius: Radius.m))
    .padding(Spacing.m)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(.appBackground)
}
