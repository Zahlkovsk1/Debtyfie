//
//  AllPeopleView.swift
//  Debby
//
//  Created by Shox on 20/10/26.
//

import SwiftUI
import SwiftData

struct AllPeopleView: View {
    private enum Sort: CaseIterable, Identifiable {
        case recent, name, balance

        var id: Self { self }

        var title: LocalizedStringKey {
            switch self {
            case .recent: "Recent activity"
            case .name: "Name"
            case .balance: "Largest balance"
            }
        }
    }

    @Query private var people: [Person]
    @AppStorage("homeCurrencyCode") private var currencyCode = "EUR"

    @State private var searchText = ""
    @State private var sort = Sort.recent
    @State private var isAddingPerson = false

    private var currency: Currency { Currency(code: currencyCode) }

    private var visiblePeople: [Person] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let matching = query.isEmpty
            ? people
            : people.filter { $0.name.localizedStandardContains(query) }

        switch sort {
        case .recent:
            return matching.sorted { $0.lastActivity > $1.lastActivity }
        case .name:
            return matching.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        case .balance:
            return matching.sorted {
                abs($0.balances[currency] ?? 0) > abs($1.balances[currency] ?? 0)
            }
        }
    }

    var body: some View {
        let _ = Self._printChanges()
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(visiblePeople) { person in
                    NavigationLink(value: person) {
                        PersonRow(person: person, currency: currency)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.m)
            .padding(.top, Spacing.s)
        }
        .background(.appBackground)
        .overlay { emptyState }
        .onAppear { print("➡️ AllPeople appeared") }
               .onDisappear { print("⬅️ AllPeople disappeared") }
        .navigationTitle("All people (\(people.count))")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search by name")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Picker("Sort by", selection: $sort) {
                        ForEach(Sort.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
                .accessibilityLabel("Sort")
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isAddingPerson = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add person")
            }
        }
        .sheet(isPresented: $isAddingPerson) {
            AddPersonView()
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if people.isEmpty {
            ContentUnavailableView {
                Label("No people yet", systemImage: "person.2")
            } description: {
                Text("Add the first person to start keeping the ledger.")
            } actions: {
                Button("Add person") { isAddingPerson = true }
                    .buttonStyle(.borderedProminent)
                    .tint(.black)
            }
        } else if visiblePeople.isEmpty {
            ContentUnavailableView.search(text: searchText)
        }
    }
}

#Preview {
    NavigationStack {
        AllPeopleView()
    }
    .modelContainer(PreviewData.container)
}
