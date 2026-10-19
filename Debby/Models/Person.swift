//
//  Person.swift
//  Debby
//
//  Created by Shox on 18/10/26.
//

import Foundation
import SwiftData

@Model
final class Person {
    var id: UUID
    var name: String
    var createdAt: Date

    @Attribute(.externalStorage)
    var photoData: Data?

    @Relationship(deleteRule: .cascade, inverse: \Entry.person)
    var entries: [Entry] = []

    init(name: String, photoData: Data? = nil) {
        self.id = UUID()
        self.name = name
        self.createdAt = .now
        self.photoData = photoData
    }

    /// For sorting the people list: the last time you added an entry for them.
    var lastActivity: Date {
        entries.map(\.createdAt).max() ?? createdAt
    }
}
