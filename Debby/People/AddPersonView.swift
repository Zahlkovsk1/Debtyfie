//
//  AddPersonView.swift
//  Debby
//
//  Created by Shox on 19/10/26.
//

import SwiftUI
import SwiftData
import PhotosUI

struct AddPersonView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    /// The person being edited, or nil when creating a new one.
    private let editing: Person?

    /// Called with the person right after saving.
    private let onSave: (Person) -> Void

    @State private var name: String
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?

    @State private var country: CallingCountry
    @State private var phoneText: String
    @State private var messenger: Messenger?
    @State private var handle: String
    @State private var note: String

    /// Cards typed in this session, not saved yet.
    @State private var cardDrafts: [CardDraft] = []
    /// Saved cards the user removed. They are only deleted when Save is tapped.
    @State private var removedCardIDs: Set<PersistentIdentifier> = []
    @State private var isAddingCard = false

    @FocusState private var nameFocused: Bool

    init(person: Person? = nil, onSave: @escaping (Person) -> Void = { _ in }) {
        editing = person
        self.onSave = onSave

        let uzbekistan = CallingCountry.country(region: "UZ")!
        _name = State(initialValue: person?.name ?? "")
        _photoData = State(initialValue: person?.photoData)
        _country = State(initialValue: person?.phoneRegion.flatMap { CallingCountry.country(region: $0) } ?? uzbekistan)
        _phoneText = State(initialValue: person?.phoneNumber ?? "")
        _messenger = State(initialValue: person?.messenger)
        _handle = State(initialValue: person?.messengerHandle ?? "")
        _note = State(initialValue: person?.note ?? "")
    }

    private var title: LocalizedStringKey {
        editing == nil ? "New person" : "Edit person"
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Cards already in the database that the user has not removed.
    private var savedCards: [PaymentCard] {
        (editing?.cards ?? [])
            .filter { !removedCardIDs.contains($0.persistentModelID) }
            .sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.l) {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        avatar
                    }
                    .buttonStyle(.plain)

                    FieldGroup("Name") {
                        TextField("Name", text: $name)
                            .font(.appBody)
                            .textInputAutocapitalization(.words)
                            .focused($nameFocused)
                            .fieldStyle()
                    }

                    FieldGroup("Phone") {
                        PhoneField(country: $country, number: $phoneText)
                    }

                    FieldGroup("Messenger") {
                        messengerSection
                    }

                    FieldGroup("Cards") {
                        cardsSection
                    }

                    FieldGroup("Note") {
                        TextField("Anything worth remembering", text: $note, axis: .vertical)
                            .font(.appBody)
                            .lineLimit(2...5)
                            .fieldStyle()
                    }
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
                        .disabled(trimmedName.isEmpty)
                }
            }
            .task { if editing == nil { nameFocused = true } }
            .onChange(of: photoItem) { _, item in loadPhoto(item) }
            .onChange(of: messenger) { handle = "" }
            .sheet(isPresented: $isAddingCard) {
                AddCardView { cardDrafts.append($0) }
            }
        }
    }

    private var messengerSection: some View {
        VStack(spacing: Spacing.s) {
            Picker("Messenger", selection: $messenger) {
                Text("None").tag(Messenger?.none)
                ForEach(Messenger.allCases, id: \.self) { messenger in
                    Text(messenger.displayName).tag(Optional(messenger))
                }
            }
            .pickerStyle(.segmented)

            if let messenger {
                TextField(
                    messenger == .telegram ? "@username" : "+39 333 123 4567",
                    text: $handle
                )
                .font(.appBody)
                .keyboardType(messenger == .telegram ? .asciiCapable : .phonePad)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .fieldStyle()
            }
        }
    }

    private var cardsSection: some View {
        VStack(spacing: Spacing.s) {
            ForEach(savedCards) { card in
                CardRow(number: card.number, holderName: card.holderName, bank: card.bank) {
                    removedCardIDs.insert(card.persistentModelID)
                }
            }

            ForEach(cardDrafts) { draft in
                CardRow(number: draft.number, holderName: draft.holderName, bank: draft.bank) {
                    cardDrafts.removeAll { $0.id == draft.id }
                }
            }

            Button {
                isAddingCard = true
            } label: {
                HStack(spacing: Spacing.m) {
                    Image(systemName: "creditcard")
                    Text("Add card")
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

    private var avatar: some View {
        ZStack {
            if let photoData, let image = UIImage(data: photoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle().fill(.surface)
                Image(systemName: "camera")
                    .font(.title)
                    .foregroundStyle(.textSecondary)
            }
        }
        .frame(width: 96, height: 96)
        .clipShape(Circle())
    }

    private func save() {
        let person = editing ?? Person(name: trimmedName, photoData: photoData)
        if editing == nil { context.insert(person) }

        person.name = trimmedName
        person.photoData = photoData

        let digits = PhoneNumber(country: country, typed: phoneText).national
        if digits.isEmpty {
            person.phoneRegion = nil
            person.phoneNumber = nil
        } else {
            person.phoneRegion = country.region
            person.phoneNumber = digits
        }

        let trimmedHandle = handle.trimmingCharacters(in: .whitespacesAndNewlines)
        if let messenger, !trimmedHandle.isEmpty {
            person.messenger = messenger
            person.messengerHandle = trimmedHandle
        } else {
            person.messenger = nil
            person.messengerHandle = nil
        }

        person.note = note.trimmingCharacters(in: .whitespacesAndNewlines)

        // Cards removed in this session disappear for real only now.
        for card in person.cards where removedCardIDs.contains(card.persistentModelID) {
            context.delete(card)
        }

        for draft in cardDrafts {
            let card = PaymentCard(number: draft.number, holderName: draft.holderName, bank: draft.bank)
            context.insert(card)
            card.person = person
        }

        onSave(person)
        dismiss()
    }

    private func loadPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self) else { return }
            photoData = Self.thumbnail(from: data)
        }
    }

    /// Shrinks the photo to at most 400 px on its longest side, as a JPEG.
    private static func thumbnail(from data: Data, maxSide: CGFloat = 400) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let longest = max(image.size.width, image.size.height)
        let scale = min(1, maxSide / longest)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.jpegData(withCompressionQuality: 0.8) { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

#Preview("New") {
    AddPersonView()
        .modelContainer(PreviewData.container)
}

#Preview("Edit") {
    AddPersonView(person: PreviewData.people[1])
        .modelContainer(PreviewData.container)
}
