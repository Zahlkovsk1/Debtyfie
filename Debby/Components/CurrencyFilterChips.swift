//
//  CurrencyFilterChips.swift
//  Debby
//
//  Created by Shox on 30/10/26.
//

import SwiftUI

/// A row of currency chips, each with its total: "EUR · 100". Tapping one selects it.
struct CurrencyFilterChips: View {
    let options: [OwedCurrency]
    let selected: Currency?
    var onSelect: (Currency) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s) {
                ForEach(options) { option in
                    chip(for: option)
                }
            }
        }
        .scrollClipDisabled()
    }

    private func chip(for option: OwedCurrency) -> some View {
        let isSelected = option.currency == selected

        return Button {
            onSelect(option.currency)
        } label: {
            Text("\(option.currency.code) · \(compact(option))")
                .font(.appHeadline)
                .foregroundStyle(isSelected ? Color.appBackground : Color.textPrimary)
                .lineLimit(1)
                .padding(.horizontal, Spacing.m)
                .padding(.vertical, Spacing.s + Spacing.xs)
                .background {
                    if isSelected {
                        Capsule().fill(Color.textPrimary)
                    } else {
                        Capsule().strokeBorder(Color.divider, lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .animation(.snappy(duration: 0.2), value: isSelected)
    }

    /// "76.500" without the decimals and the currency sign.
    private func compact(_ option: OwedCurrency) -> String {
        AmountParts(
            option.currency.formatted(minorUnits: option.total),
            fractionDigits: option.currency.fractionDigits
        ).compact
    }
}

#Preview {
    @Previewable @State var selected: Currency? = .eur

    VStack(alignment: .leading, spacing: Spacing.l) {
        CurrencyFilterChips(
            options: [
                OwedCurrency(currency: .eur, total: 10_000, people: 1),
                OwedCurrency(currency: .usd, total: 45_000, people: 1),
                OwedCurrency(currency: .rub, total: 7_650_000, people: 2)
            ],
            selected: selected
        ) { selected = $0 }

        CurrencyFilterChips(
            options: [OwedCurrency(currency: .eur, total: 10_000, people: 1)],
            selected: .eur
        ) { _ in }
    }
    .padding(Spacing.m)
}
