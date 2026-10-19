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
    @FocusState private var nameFocused: Bool

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.l) {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    avatar
                }
                .buttonStyle(.plain)

                TextField("Name", text: $name)
                    .font(.appBody)
                    .textInputAutocapitalization(.words)
                    .focused($nameFocused)
                    .padding(Spacing.m)
                    .background(.surface, in: RoundedRectangle(cornerRadius: Radius.m))

                Spacer()
            }
            .padding(Spacing.m)
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
        context.insert(person)
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
