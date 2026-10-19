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
                    BalanceHeader(minorUnits: total, currency: currencyBinding)

                    if people.isEmpty {
                        ContentUnavailableView(
                            "No people yet",
                            systemImage: "person.2",
                            description: Text("Add your first person to get started.")
                        )
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
            .overlay(alignment: .bottomTrailing) { addButton }
            .sheet(isPresented: $isAddingEntry) { AddEntryView() }
        }
    }

    private var peopleList: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("People")
                .font(.appTitle)
                .foregroundStyle(.textPrimary)

            LazyVStack(spacing: 0) {
                ForEach(sortedPeople) { person in
                    PersonRow(person: person, currency: selectedCurrency)
                    divider
                }
            }
        }
    }

    private var history: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("History")
                .font(.appTitle)
                .foregroundStyle(.textPrimary)

            LazyVStack(spacing: 0) {
                ForEach(entries) { entry in
                    HistoryRow(entry: entry)
                    divider
                }
            }
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(.divider)
            .frame(height: 1)
    }
    
    private var addButton: some View {
        Button {
            isAddingEntry = true
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.appBackground)
                .frame(width: 60, height: 60)
                .background(.textPrimary, in: Circle())
        }
        .accessibilityLabel("Add entry")
        .padding(Spacing.m)
    }
}

#Preview {
    HomeView()
        .modelContainer(PreviewData.container)
}

#Preview("Empty") {
    HomeView()
        .modelContainer(for: [Person.self, Entry.self], inMemory: true)
}

