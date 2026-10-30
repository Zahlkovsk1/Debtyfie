//
//  AddCardView.swift
//  Debby
//
//  Created by Shox on 19/10/26.
//
import SwiftUI
import SwiftData

/// A card that has been entered but not yet saved to the database.
struct CardDraft: Identifiable {
    let id = UUID()
    var number: String            // digits only
    var holderName: String
    var bankName: String
}

struct AddCardView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var savedCards: [PaymentCard]
    var onSave: (CardDraft) -> Void

    @State private var numberText = ""
    @State private var holderName = ""
    @State private var bankName = ""
    @FocusState private var numberFocused: Bool

    private var digits: String { numberText.filter { $0.isASCII && $0.isNumber } }
    private var network: CardNetwork? { CardNetwork(number: digits) }
    private var canSave: Bool { digits.count >= 12 }
    private var looksWrong: Bool { digits.count >= 16 && !CardNetwork.passesLuhnCheck(digits) }

    /// Bank names already used on other cards, most used first. Narrowed by what is typed.
    private var suggestions: [String] {
        var used: [String: (name: String, count: Int)] = [:]
        for card in savedCards {
            let name = card.bankName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { continue }
            used[name.lowercased(), default: (name, 0)].count += 1
        }

        let typed = bankName.trimmingCharacters(in: .whitespacesAndNewlines)
        return used.values
            .filter { entry in
                typed.isEmpty || (
                    entry.name.localizedCaseInsensitiveContains(typed)
                    && entry.name.caseInsensitiveCompare(typed) != .orderedSame
                )
            }
            .sorted { $0.count != $1.count ? $0.count > $1.count : $0.name < $1.name }
            .prefix(6)
            .map { $0.name }
    }

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
                        VStack(alignment: .leading, spacing: Spacing.s) {
                            TextField("Bank name", text: $bankName)
                                .font(.appBody)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                                .fieldStyle()

                            if !suggestions.isEmpty {
                                suggestionRow
                            }
                        }
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

    private var suggestionRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s) {
                ForEach(suggestions, id: \.self) { name in
                    Button {
                        bankName = name
                    } label: {
                        Text(name)
                            .font(.appBody)
                            .foregroundStyle(.textPrimary)
                            .padding(.horizontal, Spacing.m)
                            .padding(.vertical, Spacing.s)
                            .background(.surface, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func save() {
        onSave(CardDraft(
            number: digits,
            holderName: holderName.trimmingCharacters(in: .whitespacesAndNewlines),
            bankName: bankName.trimmingCharacters(in: .whitespacesAndNewlines)
        ))
        dismiss()
    }
}

#Preview {
    AddCardView { _ in }
        .modelContainer(PreviewData.container)
}
