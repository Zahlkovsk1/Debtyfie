//
//  AddCardView.swift
//  Debby
//
//  Created by Shox on 19/10/26.
//

import SwiftUI

/// A card that has been entered but not yet saved to the database.
struct CardDraft: Identifiable {
    let id = UUID()
    var number: String            // digits only
    var holderName: String
    var bank: Bank?
}

struct AddCardView: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: (CardDraft) -> Void

    @State private var numberText = ""
    @State private var holderName = ""
    @State private var bank: Bank?
    @FocusState private var numberFocused: Bool

    private var digits: String { numberText.filter { $0.isASCII && $0.isNumber } }
    private var network: CardNetwork? { CardNetwork(number: digits) }
    private var canSave: Bool { digits.count >= 12 }
    private var looksWrong: Bool { digits.count >= 16 && !CardNetwork.passesLuhnCheck(digits) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.l) {
                    FieldGroup("Card number") {
                        VStack(alignment: .leading, spacing: Spacing.s) {
                            HStack(spacing: Spacing.s) {
                                TextField("0000 0000 0000 0000", text: $numberText)
                                    .font(.appAmount)
                                    .keyboardType(.numberPad)
                                    .focused($numberFocused)
                                if let network {
                                    CardBadge(text: network.displayName)
                                }
                            }
                            .fieldStyle()

                            if looksWrong {
                                Label(
                                    "These digits don't pass the card check. Compare them with the original once more.",
                                    systemImage: "exclamationmark.triangle"
                                )
                                .font(.appCaption)
                                .foregroundStyle(.textPrimary)
                            }
                        }
                    }

                    FieldGroup("Name on card (optional)") {
                        TextField("ALI KARIMOV", text: $holderName)
                            .font(.appBody)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .fieldStyle()
                    }

                    FieldGroup("Bank (optional)") {
                        Picker("Bank", selection: $bank) {
                            Text("None").tag(Bank?.none)
                            ForEach(Bank.allCases, id: \.self) { bank in
                                Text(bank.displayName).tag(Optional(bank))
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding(Spacing.m)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(.appBackground)
            .navigationTitle("New card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!canSave)
                }
            }
            .task { numberFocused = true }
            .onChange(of: numberText) { _, newValue in
                let cleaned = String(newValue.filter { $0.isASCII && $0.isNumber }.prefix(19))
                let grouped = CardNetwork.grouped(cleaned)
                if grouped != newValue { numberText = grouped }
            }
        }
    }

    private func save() {
        onSave(CardDraft(
            number: digits,
            holderName: holderName.trimmingCharacters(in: .whitespacesAndNewlines),
            bank: bank
        ))
        dismiss()
    }
}

#Preview {
    AddCardView { _ in }
}
