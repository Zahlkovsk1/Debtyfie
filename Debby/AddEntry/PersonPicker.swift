//
//  PersonPicker.swift
//  Debby
//
//  Created by Shox on 19/10/26.
//
import SwiftUI
import SwiftData

struct PersonPicker: View {
    @Binding var selection: Person?
    @Query private var people: [Person]
    @Environment(\.dismiss) private var dismiss

    @State private var isAddingPerson = false
    /// Set when a person was created in the sheet, so this screen can close too.
    @State private var addedPerson = false

    private var sortedPeople: [Person] {
        people.sorted { $0.lastActivity > $1.lastActivity }
    }

    var body: some View {
        List {
            Button {
                isAddingPerson = true
            } label: {
                HStack(spacing: Spacing.m) {
                    ZStack {
                        Circle().fill(.surface)
                        Image(systemName: "plus")
                            .font(.headline)
                            .foregroundStyle(.textPrimary)
                    }
                    .frame(width: 40, height: 40)

                    Text("New person")
                        .font(.appBody)
                        .foregroundStyle(.textPrimary)
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            ForEach(sortedPeople) { person in
                Button {
                    selection = person
                    dismiss()
                } label: {
                    HStack(spacing: Spacing.m) {
                        PersonAvatar(person: person, size: 40)
                        Text(person.name)
                            .font(.appBody)
                            .foregroundStyle(.textPrimary)
                        Spacer()
                        if selection?.id == person.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.textPrimary)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Select person")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isAddingPerson, onDismiss: {
            if addedPerson { dismiss() }
        }) {
            AddPersonView { person in
                selection = person
                addedPerson = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        PersonPicker(selection: .constant(nil))
    }
    .modelContainer(PreviewData.container)
}
