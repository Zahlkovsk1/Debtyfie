//
//  CountryPicker.swift
//  Debby
//
//  Created by Shox on 19/10/26.
//
import SwiftUI

struct CountryPicker: View {
    @Binding var selection: CallingCountry
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var matches: [CallingCountry] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return CallingCountry.all }
        return CallingCountry.all.filter {
            $0.name.localizedCaseInsensitiveContains(query)
            || $0.displayCode.contains(query)
            || $0.region.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if searchText.isEmpty {
                    Section("Frequent") {
                        ForEach(CallingCountry.frequent) { row($0) }
                    }
                }
                Section(searchText.isEmpty ? "All countries" : "Results") {
                    ForEach(matches) { row($0) }
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "Search country or code")
            .navigationTitle("Country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) { dismiss() }
                }
            }
        }
    }

    private func row(_ country: CallingCountry) -> some View {
        Button {
            selection = country
            dismiss()
        } label: {
            HStack(spacing: Spacing.m) {
                Text(country.flag)
                    .font(.title2)
                Text(country.name)
                    .font(.appBody)
                    .foregroundStyle(.textPrimary)
                Spacer()
                Text(country.displayCode)
                    .font(.appBody)
                    .foregroundStyle(.textSecondary)
                if country == selection {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.textPrimary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var country = CallingCountry.country(region: "UZ")!
    CountryPicker(selection: $country)
}
