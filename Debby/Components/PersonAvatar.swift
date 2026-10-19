//
//  PersonAvatar.swift
//  Debby
//
//  Created by Shox on 19/10/26.
//


import SwiftUI

struct PersonAvatar: View {
    let person: Person
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let data = person.photoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Text(initials)
                    .font(.appHeadline)
                    .foregroundStyle(.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.surface)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    /// "Ali Karimov" → "AK", "Baga" → "B"
    private var initials: String {
        person.name
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map { String($0) }
            .joined()
            .uppercased()
    }
}
