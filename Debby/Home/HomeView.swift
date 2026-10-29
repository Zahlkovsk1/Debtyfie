//
//  HomeView.swift
//  Debby
//
//  Created by Shox on 19/10/26.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var people: [Person]
    @Query(sort: \Entry.date, order: .reverse) private var entries: [Entry]
    @AppStorage("homeCurrencyCode") private var currencyCode = "EUR"
    @State private var isAddingEntry = false
    @State private var isAddingPerson = false
    @State private var editingEntry: Entry?

    private var selectedCurrency: Currency { Currency(code: currencyCode) }

    private var currencyBinding: Binding<Currency> {
        Binding(
            get: { Currency(code: currencyCode) },
            set: { currencyCode = $0.code }
        )
    }

    private var sortedPeople: [Person] {
        people.sorted { $0.lastActivity > $1.lastActivity }
    }

    private var total: Int {
        people.totalBalances()[selectedCurrency] ?? 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    VStack(alignment: .leading, spacing: Spacing.m) {
                        BalanceHeader(minorUnits: total, currency: selectedCurrency)
                        chips
                    }

                    if people.isEmpty {
                        emptyState
                    } else {
                        peopleList
                        if !entries.isEmpty {
                            history
                        }
                    }
                }
                .padding(.horizontal, Spacing.m)
                .padding(.top, Spacing.m)
                .padding(.bottom, 96)
            }
            .background(.appBackground)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Person.self) { PersonDetailView(person: $0) }
            .overlay(alignment: .bottomTrailing) { addButton }
            .sheet(isPresented: $isAddingEntry) { AddEntryView() }
            .sheet(isPresented: $isAddingPerson) { AddPersonView() }
        }
    }

    private var chips: some View {
        HStack(spacing: Spacing.s) {
            CurrencyChip(currency: currencyBinding, isProminent: true)
            if !people.isEmpty {
                allPeopleChip
                owedChip
            }
        }
    }

    private var owedChip: some View {
        NavigationLink {
            OwedView()
        } label: {
            HStack(spacing: Spacing.s) {
                Image(systemName: "scalemass")
                Text("Owed")
                    .font(.appHeadline)
            }
            .filledChip()
        }
        .buttonStyle(.plain)
    }

    private var allPeopleChip: some View {
        NavigationLink {
            AllPeopleView()
        } label: {
            HStack(spacing: Spacing.s) {
                Image(systemName: "list.bullet")
                Text("All people")
                    .font(.appHeadline)
            }
            .filledChip()
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No people yet", systemImage: "person.2")
        } description: {
            Text("Add your first person to get started.")
        } actions: {
            Button("Add person") { isAddingPerson = true }
                .buttonStyle(.borderedProminent)
                .tint(.textPrimary)
        }
    }

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.m),
        GridItem(.flexible(), spacing: Spacing.m)
    ]

    /// How many people the home grid shows before "See all".
    private let gridLimit = 6

    private var peopleList: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack {
                Text("People")
                    .font(.appTitle)
                    .foregroundStyle(.textPrimary)
                Spacer()
                if people.count > gridLimit {
                    NavigationLink {
                        AllPeopleView()
                    } label: {
                        HStack(spacing: Spacing.xs) {
                            Text("See all")
                            Image(systemName: "chevron.right")
                        }
                        .font(.appBody)
                        .foregroundStyle(.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            LazyVGrid(columns: columns, spacing: Spacing.m) {
                ForEach(sortedPeople.prefix(gridLimit)) { person in
                    NavigationLink(value: person) {
                        PersonCard(person: person, currency: selectedCurrency)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var history: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("History")
                .font(.appTitle)
                .foregroundStyle(.textPrimary)

            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(entries.groupedByDay()) { group in
                    DayHeader(title: group.title())
                    ForEach(group.entries) { entry in
                        Button {
                            editingEntry = entry
                        } label: {
                            HistoryRow(entry: entry)
                        }
                        .buttonStyle(.plain)
                        divider
                    }
                }
            }
        }
        .sheet(item: $editingEntry) { AddEntryView(entry: $0) }
    }

    private var divider: some View {
        Rectangle()
            .fill(.divider)
            .frame(height: 1)
    }

    private var addButton: some View {
          FloatingAddButton(label: "Add entry") { isAddingEntry = true }
      }
}

#Preview {
    HomeView()
        .modelContainer(PreviewData.container)
}

#Preview("Empty") {
    HomeView()
        .modelContainer(for: [Person.self, Entry.self, PaymentCard.self], inMemory: true)
}

