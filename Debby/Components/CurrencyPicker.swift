//
//  CurrencyPicker.swift
//  Debby
//
//  Created by Shox on 19/10/26.
//

import SwiftUI

struct CurrencyPicker: View {
    @Binding var selection: Currency
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private let frequent: [Currency] = [.eur, .usd, .rub, .uzs]

    private var matches: [Currency] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return Currency.supported }
        return Currency.supported.filter {
            $0.code.localizedCaseInsensitiveContains(query)
            || $0.name.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if searchText.isEmpty {
                    Section("Frequent") {
                        ForEach(frequent) { row($0) }
                    }
                }
                Section(searchText.isEmpty ? "All currencies" : "Results") {
                    ForEach(matches) { row($0) }
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "Search currency")
            .navigationTitle("Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) { dismiss() }
                }
            }
        }
    }

    private func row(_ currency: Currency) -> some View {
        Button {
            selection = currency
            dismiss()
        } label: {
            HStack(spacing: Spacing.m) {
                Text(currency.flag)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(currency.code)
                        .font(.appHeadline)
                        .foregroundStyle(.textPrimary)
                    Text(currency.name)
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }
                Spacer()
                if currency == selection {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.textPrimary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
