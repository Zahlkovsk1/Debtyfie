//
//  FilledChip.swift
//  Debby
//
//  Created by Shox on 21/10/26.
//

import Foundation
import SwiftUI

extension View {
    /// The filled chip look: black with white text in light mode,
    /// white with black text in dark mode. Both colours already follow the scheme.
    func filledChip() -> some View {
        self
            .foregroundStyle(.appBackground)
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.s)
            .background(.textPrimary, in: Capsule())
    }
}

#Preview {
    HStack(spacing: Spacing.s) {
        Text("EUR").font(.appHeadline).filledChip()
        Text("All people").font(.appHeadline).filledChip()
    }
}
