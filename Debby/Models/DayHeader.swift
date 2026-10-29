//
//  DayHeader.swift
//  Debby
//
//  Created by Shox on 20/10/26.
//

import SwiftUI

struct DayHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.appHeadline)
            .foregroundStyle(.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, Spacing.m)
            .padding(.bottom, Spacing.xs)
    }
}

#Preview {
    DayHeader(title: "Today")
        .padding(.horizontal, Spacing.m)
}
