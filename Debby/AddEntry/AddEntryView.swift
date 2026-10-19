//
//  AddEntryView.swift
//  Debby
//
//  Created by Shox on 19/10/26.
//
import SwiftUI
import SwiftData

struct AddEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var person: Person?
    @State private var direction: Direction = .gave
    @State private var amountText = ""
    @State private var currency: Currency

    init(person: Person? = nil) {
        _person = State(initialValue: person)
        // Start with the currency that is selected on the home screen.
        let code = UserDefaults.standard.string(forKey: "homeCurrencyCode") ?? "EUR"
        _currency = State(initialValue: Currency(code: code))
    }

    private var amount: Decimal? {
        guard let value = AmountParser.parse(amountText), value > 0 else { return nil }
        return value
    }

    private var canSave: Bool { person != nil && amount != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    personField
                    directionField
                    amountField
                }
                .padding(Spacing.m)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(.appBackground)
            .navigationTitle("New entry")
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
            .onChange(of: amountText) { _, text in
                let limited = AmountParser.limitingDecimals(text, to: currency.fractionDigits)
                if limited != text { amountText = limited }
            }
            .onChange(of: currency) { _, newCurrency in
                amountText = AmountParser.limitingDecimals(amountText, to: newCurrency.fractionDigits)
            }
        }
    }

    private var personField: some View {
        FieldGroup("Person") {
            NavigationLink {
                PersonPicker(selection: $person)
            } label: {
                HStack(spacing: Spacing.m) {
                    if let person {
                        PersonAvatar(person: person, size: 36)
                        Text(person.name)
                            .font(.appBody)
                            .foregroundStyle(.textPrimary)
                    } else {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.title2)
                            .foregroundStyle(.textSecondary)
                        Text("Select person")
                            .font(.appBody)
                            .foregroundStyle(.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }
                .fieldStyle()
            }
            .buttonStyle(.plain)
        }
    }

    private var directionField: some View {
        FieldGroup("Type") {
            Picker("Type", selection: $direction) {
                Text("You gave").tag(Direction.gave)
                Text("You received").tag(Direction.received)
            }
            .pickerStyle(.segmented)
        }
    }

    private var amountField: some View {
        FieldGroup("Amount") {
            HStack(spacing: Spacing.m) {
                TextField("0", text: $amountText)
                    .font(.appBalance)
                    .keyboardType(.decimalPad)
                    .minimumScaleFactor(0.5)
                CurrencyChip(currency: $currency)
            }
        }
    }

    private func save() {
        guard let person, let amount else { return }
        context.insert(Entry(person: person, direction: direction, amount: amount, currency: currency))
        dismiss()
    }
}

#Preview {
    AddEntryView()
        .modelContainer(PreviewData.container)
}
