//
//  FloatingAddButton.swift
//  Debby
//
//  Created by Shox on 21/10/26.
//

import SwiftUI

/// The round black/white "+" that floats in the bottom corner.
struct FloatingAddButton: View {
    let label: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.appBackground)
                .frame(width: 60, height: 60)
                .background(.textPrimary, in: Circle())
        }
        .accessibilityLabel(label)
        .padding(Spacing.m)
    }
}

#Preview {
    FloatingAddButton(label: "Add entry") {}
}
