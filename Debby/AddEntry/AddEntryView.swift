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
    @State private var person: Person?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    personField
                }
                .padding(Spacing.m)
            }
            .background(.appBackground)
            .navigationTitle("New entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) { dismiss() }
                }
            }
        }
    }

    private var personField: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Person")
                .font(.appCaption)
                .foregroundStyle(.textSecondary)

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
                .padding(Spacing.m)
                .background(.surface, in: RoundedRectangle(cornerRadius: Radius.m))
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    AddEntryView()
        .modelContainer(PreviewData.container)
}
