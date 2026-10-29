//
//  CurrencyChip.swift
//  Debby
//
//  Created by Shox on 19/10/26.
//

import SwiftUI

struct CurrencyChip: View {
    @Binding var currency: Currency
    /// Black/white filled style for the main screens. The default is the quiet grey one.
    var isProminent = false

    @State private var isPickerShown = false

    var body: some View {
        Button {
            isPickerShown = true
        } label: {
            label
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isPickerShown) {
            CurrencyPicker(selection: $currency)
                .presentationDetents([.medium, .large])
        }
    }

    @ViewBuilder
    private var label: some View {
        let content = HStack(spacing: Spacing.xs) {
            Text(currency.code)
                .font(.appHeadline)
            Image(systemName: "chevron.down")
                .font(.caption2.weight(.bold))
        }

        if isProminent {
            content.filledChip()
        } else {
            content
                .foregroundStyle(.textPrimary)
                .padding(.horizontal, Spacing.s + Spacing.xs)
                .padding(.vertical, Spacing.s)
                .background(.surface, in: RoundedRectangle(cornerRadius: Radius.s))
        }
    }
}

#Preview {
    @Previewable @State var currency = Currency.eur

    VStack(spacing: Spacing.l) {
        CurrencyChip(currency: $currency)
        CurrencyChip(currency: $currency, isProminent: true)
        Text("Selected: \(currency.code)")
            .font(.appBody)
            .foregroundStyle(.textSecondary)
    }
}
