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

    private var sortedPeople: [Person] {
        people.sorted { $0.lastActivity > $1.lastActivity }
    }

    var body: some View {
        List {
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
        .overlay {
            if people.isEmpty {
                ContentUnavailableView(
                    "No people yet",
                    systemImage: "person.2",
                    description: Text("Add a person first.")
                )
            }
        }
        .navigationTitle("Select person")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PersonPicker(selection: .constant(nil))
    }
    .modelContainer(PreviewData.container)
}
