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

    /// Called with the new person right after saving.
    var onSave: (Person) -> Void = { _ in }

    @State private var name = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?

    @State private var country = CallingCountry.country(region: "UZ")!
    @State private var phoneText = ""
    @State private var messenger: Messenger?
    @State private var handle = ""
    @State private var note = ""
    @State private var cardDrafts: [CardDraft] = []
    @State private var isAddingCard = false
    
    @FocusState private var nameFocused: Bool

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
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
            .navigationTitle("New person")
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
            .task { nameFocused = true }
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
        let person = Person(name: trimmedName, photoData: photoData)

        let digits = PhoneNumber(country: country, typed: phoneText).national
        if !digits.isEmpty {
            person.phoneRegion = country.region
            person.phoneNumber = digits
        }

        let trimmedHandle = handle.trimmingCharacters(in: .whitespacesAndNewlines)
        if let messenger, !trimmedHandle.isEmpty {
            person.messenger = messenger
            person.messengerHandle = trimmedHandle
        }

        person.note = note.trimmingCharacters(in: .whitespacesAndNewlines)

        context.insert(person)
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

#Preview {
    AddPersonView()
        .modelContainer(PreviewData.container)
}
