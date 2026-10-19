//
//  AddEntryView.swift
//  Debby
//
//  Created by Shox on 19/10/26.
//
import SwiftUI
import SwiftData

struct AddEntryView: View {
    private enum Field: Hashable { case amount, rate, counter }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    /// The entry being edited, or nil when creating a new one.
    private let editing: Entry?

    @State private var person: Person?
    @State private var direction: Direction = .gave
    @State private var amountText = ""
    @State private var currency: Currency

    @State private var hasSecondCurrency = false
    @State private var counterCurrency = Currency.usd
    @State private var rateText = ""
    @State private var counterText = ""

    @State private var date = Date.now
    @State private var note = ""

    @State private var isConfirmingDelete = false
    @FocusState private var focus: Field?

    init(person: Person? = nil, entry: Entry? = nil) {
        editing = entry
        if let entry {
            _person = State(initialValue: entry.person)
            _direction = State(initialValue: entry.direction)
            _currency = State(initialValue: entry.currency)
            _amountText = State(initialValue: ConversionMath.text(
                entry.amount, maxDecimals: entry.currency.fractionDigits))
            _date = State(initialValue: entry.date)
            _note = State(initialValue: entry.note)
            if let conversion = entry.conversion {
                _hasSecondCurrency = State(initialValue: true)
                _counterCurrency = State(initialValue: conversion.currency)
                _rateText = State(initialValue: ConversionMath.text(
                    conversion.rate, maxDecimals: ConversionMath.rateDigits))
                _counterText = State(initialValue: ConversionMath.text(
                    conversion.amount, maxDecimals: conversion.currency.fractionDigits))
            }
        } else {
            _person = State(initialValue: person)
            // Start with the currency that is selected on the home screen.
            let code = UserDefaults.standard.string(forKey: "homeCurrencyCode") ?? "EUR"
            _currency = State(initialValue: Currency(code: code))
        }
    }

    // MARK: Values

    private var title: LocalizedStringKey {
        editing == nil ? "New entry" : "Edit entry"
    }

    private var amount: Decimal? {
        guard let value = AmountParser.parse(amountText), value > 0 else { return nil }
        return value
    }

    private var rate: Decimal? {
        guard let value = AmountParser.parse(rateText), value > 0 else { return nil }
        return value
    }

    private var counterAmount: Decimal? {
        guard let value = AmountParser.parse(counterText), value > 0 else { return nil }
        return value
    }

    private var conversion: Conversion? {
        guard hasSecondCurrency, counterCurrency != currency,
              let counterAmount, let rate else { return nil }
        return Conversion(currency: counterCurrency, amount: counterAmount, rate: rate)
    }

    private var canSave: Bool {
        person != nil && amount != nil && (!hasSecondCurrency || conversion != nil)
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    personField
                    directionField
                    amountField
                    secondCurrencyField
                    dateField
                    noteField
                    if editing != nil { deleteButton }
                }
                .padding(Spacing.m)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(.appBackground)
            .navigationTitle(title)
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
            .confirmationDialog(
                "Delete this entry?",
                isPresented: $isConfirmingDelete,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive, action: deleteEntry)
            } message: {
                Text("The balance will change accordingly. This can't be undone.")
            }
            .onChange(of: amountText) { _, text in
                let limited = AmountParser.limitingDecimals(text, to: currency.fractionDigits)
                if limited != text { amountText = limited; return }
                if hasSecondCurrency { amountChanged() }
            }
            .onChange(of: currency) { old, new in
                focus = nil
                amountText = AmountParser.limitingDecimals(amountText, to: new.fractionDigits)
                if hasSecondCurrency && new == counterCurrency { counterCurrency = old }
            }
            .onChange(of: rateText) { _, text in
                let limited = AmountParser.limitingDecimals(text, to: ConversionMath.rateDigits)
                if limited != text { rateText = limited; return }
                if focus == .rate { counterFromRate() }
            }
            .onChange(of: counterText) { _, text in
                let limited = AmountParser.limitingDecimals(text, to: counterCurrency.fractionDigits)
                if limited != text { counterText = limited; return }
                if focus == .counter { rateFromCounter() }
            }
            .onChange(of: counterCurrency) { _, new in
                focus = nil
                if rate != nil {
                    counterFromRate()
                } else {
                    counterText = AmountParser.limitingDecimals(counterText, to: new.fractionDigits)
                }
            }
        }
    }

    // MARK: Fields

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
                    .focused($focus, equals: .amount)
                CurrencyChip(currency: $currency)
            }
        }
    }

    @ViewBuilder
    private var secondCurrencyField: some View {
        if hasSecondCurrency {
            FieldGroup("Second currency") {
                VStack(spacing: Spacing.s) {
                    HStack(spacing: Spacing.m) {
                        Text("Balance changes in")
                            .font(.appBody)
                            .foregroundStyle(.textSecondary)
                        Spacer()
                        CurrencyChip(currency: $counterCurrency)
                        Button(action: removeSecondCurrency) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.textSecondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove second currency")
                    }

                    HStack(spacing: Spacing.s) {
                        Text("1 \(currency.code) =")
                            .font(.appBody)
                            .foregroundStyle(.textSecondary)
                        TextField("Rate", text: $rateText)
                            .font(.appAmount)
                            .keyboardType(.decimalPad)
                            .focused($focus, equals: .rate)
                        Text(counterCurrency.code)
                            .font(.appBody)
                            .foregroundStyle(.textSecondary)
                    }
                    .fieldStyle()

                    HStack(spacing: Spacing.s) {
                        TextField("Amount", text: $counterText)
                            .font(.appAmount)
                            .keyboardType(.decimalPad)
                            .focused($focus, equals: .counter)
                        Text(counterCurrency.code)
                            .font(.appBody)
                            .foregroundStyle(.textSecondary)
                    }
                    .fieldStyle()

                    if counterCurrency == currency {
                        Text("Choose a different currency.")
                            .font(.appCaption)
                            .foregroundStyle(.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("The balance changes in \(counterCurrency.code). \(currency.code) is the cash that moved. Type the rate or the amount, and the other is calculated.")
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        } else {
            Button(action: addSecondCurrency) {
                HStack(spacing: Spacing.m) {
                    Image(systemName: "arrow.left.arrow.right")
                    Text("Add second currency and rate")
                    Spacer()
                    Image(systemName: "plus")
                }
                .font(.appBody)
                .foregroundStyle(.textPrimary)
                .fieldStyle()
            }
            .buttonStyle(.plain)
        }
    }

    private var dateField: some View {
        FieldGroup("Date and time") {
            HStack {
                Text("When")
                    .font(.appBody)
                    .foregroundStyle(.textPrimary)
                Spacer()
                DatePicker(
                    "When",
                    selection: $date,
                    in: ...Date.now,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .labelsHidden()
            }
            .fieldStyle()
        }
    }

    private var noteField: some View {
        FieldGroup("Note (optional)") {
            TextField("Gold chain 18k, 12 g…", text: $note, axis: .vertical)
                .font(.appBody)
                .lineLimit(2...5)
                .fieldStyle()
        }
    }

    private var deleteButton: some View {
        Button {
            isConfirmingDelete = true
        } label: {
            Text("Delete entry")
                .font(.appBody)
                .foregroundStyle(.negative)
                .frame(maxWidth: .infinity)
                .fieldStyle()
        }
        .buttonStyle(.plain)
    }

    // MARK: Actions

    private func addSecondCurrency() {
        counterCurrency = (currency == .eur) ? .usd : .eur
        rateText = ""
        counterText = ""
        hasSecondCurrency = true
    }

    private func removeSecondCurrency() {
        focus = nil
        hasSecondCurrency = false
        rateText = ""
        counterText = ""
    }

    private func counterFromRate() {
        guard let amount, let rate else {
            counterText = ""
            return
        }
        let value = ConversionMath.counterAmount(amount: amount, rate: rate, in: counterCurrency)
        counterText = ConversionMath.text(value, maxDecimals: counterCurrency.fractionDigits)
    }

    private func rateFromCounter() {
        guard let amount, let counterAmount,
              let value = ConversionMath.rate(amount: amount, counterAmount: counterAmount) else {
            rateText = ""
            return
        }
        rateText = ConversionMath.text(value, maxDecimals: ConversionMath.rateDigits)
    }

    /// The amount changed: the rate stays, the second amount follows.
    private func amountChanged() {
        if rate != nil {
            counterFromRate()
        } else if counterAmount != nil {
            rateFromCounter()
        }
    }

    private func save() {
        guard let person, let amount else { return }
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        if let editing {
            editing.update(
                person: person, date: date, direction: direction, amount: amount,
                currency: currency, conversion: conversion, note: trimmedNote
            )
        } else {
            context.insert(Entry(
                person: person, date: date, direction: direction, amount: amount,
                currency: currency, conversion: conversion, note: trimmedNote
            ))
        }
        dismiss()
    }

    private func deleteEntry() {
        guard let doomed = editing else { return }
        dismiss()
        Task {
            // Let the sheet slide away before the record disappears from under it.
            try? await Task.sleep(for: .milliseconds(400))
            context.delete(doomed)
            try? context.save()
        }
    }
}

#Preview("New") {
    AddEntryView()
        .modelContainer(PreviewData.container)
}

#Preview("Edit") {
    AddEntryView(entry: PreviewData.entries[0])
        .modelContainer(PreviewData.container)
}
