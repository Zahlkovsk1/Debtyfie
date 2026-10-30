//
//  PersonDetailView.swift
//  Debby
//
//  Created by Shox on 19/10/26.
//

import SwiftUI
import SwiftData

struct PersonDetailView: View {
    let person: Person
    @AppStorage("homeCurrencyCode") private var currencyCode = "EUR"
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var isConfirmingDelete = false
    @State private var editingEntry: Entry?
    @State private var isEditing = false
    @State private var isAddingEntry = false
    
    private var currency: Currency { Currency(code: currencyCode) }

    private var currencyBinding: Binding<Currency> {
        Binding(
            get: { Currency(code: currencyCode) },
            set: { currencyCode = $0.code }
        )
    }

    private var sortedCards: [PaymentCard] {
        person.cards.sorted { $0.createdAt < $1.createdAt }
    }

    private var sortedEntries: [Entry] {
        person.entries.sorted { $0.date > $1.date }
    }

    private var hasContact: Bool {
        person.phone != nil || person.messengerURL != nil
    }

    var body: some View {
        let _ = Self._printChanges()
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                header

                VStack(alignment: .leading, spacing: Spacing.m) {
                    BalanceHeader(minorUnits: person.balances[currency] ?? 0, currency: currency)
                    CurrencyChip(currency: currencyBinding, isProminent: true)
                }
                if !sortedEntries.isEmpty { timelineLink }
                if hasContact { contact }
                if !sortedCards.isEmpty { cards }
                if !person.note.isEmpty { note }
                if !sortedEntries.isEmpty { history }
            }
            .padding(.horizontal, Spacing.m)
            .padding(.top, Spacing.m)
            .padding(.bottom, 96)
        }
        .background(.appBackground)
        .onAppear { print("➡️ PersonDetail appeared") }
                .onDisappear { print("⬅️ PersonDetail disappeared") }
        .overlay(alignment: .bottomTrailing) {
            FloatingAddButton(label: "Add entry") { isAddingEntry = true }
        }
        .sheet(isPresented: $isAddingEntry) {
            AddEntryView(person: person)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
                   ToolbarItem(placement: .primaryAction) {
                       Menu {
                           Button {
                                              isEditing = true
                                          } label: {
                                              Label("Edit", systemImage: "pencil")
                                          }
                           
                           Button("Delete person", systemImage: "trash", role: .destructive) {
                               isConfirmingDelete = true
                           }
                       } label: {
                           Image(systemName: "ellipsis")
                       }
                   }
               }
               .confirmationDialog(
                   "Delete \(person.name)?",
                   isPresented: $isConfirmingDelete,
                   titleVisibility: .visible
               ) {
                   Button("Delete", role: .destructive, action: deletePerson)
               } message: {
                   Text("This also deletes all their entries (\(person.entries.count)) and cards (\(person.cards.count)). This can't be undone.")
               }
               .sheet(isPresented: $isEditing) {
                   AddPersonView(person: person)
               }
    }

    private var header: some View {
        HStack(spacing: Spacing.m) {
            PersonAvatar(person: person, size: 64)
            Text(person.name)
                .font(.appTitle)
                .foregroundStyle(.textPrimary)
        }
    }
    
    private var timelineLink: some View {
        NavigationLink {
            TimelineView(person: person)
        } label: {
            HStack(spacing: Spacing.m) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title3)
                    .foregroundStyle(.textPrimary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Timeline")
                        .font(.appHeadline)
                        .foregroundStyle(.textPrimary)
                    Text("Phases and repayments")
                        .font(.appCaption)
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
    

    private var contact: some View {
        FieldGroup("Contact") {
            VStack(spacing: Spacing.s) {
                if let phone = person.phone {
                    ContactRow(icon: "phone", title: "Phone", value: phone.display, url: phone.callURL)
                }
                if let messenger = person.messenger, let handle = person.messengerHandle {
                    ContactRow(
                        icon: messenger == .telegram ? "paperplane" : "message",
                        title: LocalizedStringKey(messenger.displayName),
                        value: messenger == .telegram && !handle.hasPrefix("@") ? "@" + handle : handle,
                        url: person.messengerURL
                    )
                }
            }
        }
    }

    private var cards: some View {
        FieldGroup("Cards") {
            VStack(spacing: Spacing.s) {
                ForEach(sortedCards) { card in
                    CardRow(number: card.number, holderName: card.holderName, bankName: card.bankName)
                }
            }
        }
    }

    private var note: some View {
        FieldGroup("Note") {
            Text(person.note)
                .font(.appBody)
                .foregroundStyle(.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fieldStyle()
        }
    }

    private var history: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("History")
                .font(.appTitle)
                .foregroundStyle(.textPrimary)

            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(sortedEntries.groupedByDay()) { group in
                    DayHeader(title: group.title())
                    ForEach(group.entries) { entry in
                        Button {
                            editingEntry = entry
                        } label: {
                            HistoryRow(entry: entry, showsPerson: false)
                        }
                        .buttonStyle(.plain)
                        Rectangle()
                            .fill(.divider)
                            .frame(height: 1)
                    }
                }
            }
        }
        .sheet(item: $editingEntry) { AddEntryView(entry: $0) }
    }
    
    private func deletePerson() {
        let doomed = person
        dismiss()
        Task {
            // Wait for the screen to slide away first. Deleting a person while their
            // screen is still drawing it would make SwiftUI read a deleted record.
            try? await Task.sleep(for: .milliseconds(400))
            context.delete(doomed)
            try? context.save()
        }
    }
}

#Preview {
    NavigationStack {
        PersonDetailView(person: PreviewData.people[1])   // Ali
    }
    .modelContainer(PreviewData.container)
}
