//
//  CurrencyChip.swift
//  Debby
//
//  Created by Shox on 19/10/26.
//

import SwiftUI

struct CurrencyChip: View {
    @Binding var currency: Currency
    @State private var isPickerShown = false

    var body: some View {
        Button {
            isPickerShown = true
        } label: {
            HStack(spacing: Spacing.xs) {
                Text(currency.code)
                    .font(.appHeadline)
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
            }
            .foregroundStyle(.textPrimary)
            .padding(.horizontal, Spacing.s + Spacing.xs)
            .padding(.vertical, Spacing.s)
            .background(.surface, in: RoundedRectangle(cornerRadius: Radius.s))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isPickerShown) {
            CurrencyPicker(selection: $currency)
                .presentationDetents([.medium, .large])
        }
    }
}

#Preview {
    @Previewable @State var currency = Currency.eur

    VStack(spacing: Spacing.l) {
        CurrencyChip(currency: $currency)
        Text("Selected: \(currency.code)")
            .font(.appBody)
            .foregroundStyle(.textSecondary)
    }
}
