//
//  DeletionTests.swift
//  DebbyTests
//
//  Created by Shox on 19/10/26.
//

import Testing
import Foundation
import SwiftData
@testable import Debby

@MainActor
struct DeletionTests {
    @Test func deletingAPersonDeletesTheirEntriesAndCardsOnly() throws {
        let container = try ModelContainer(
            for: Person.self, Entry.self, PaymentCard.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let ali = Person(name: "Ali")
        let bob = Person(name: "Bob")
        context.insert(ali)
        context.insert(bob)
        context.insert(Entry(person: ali, direction: .gave, amount: 100, currency: .eur))
        context.insert(Entry(person: bob, direction: .gave, amount: 50, currency: .eur))
        let card = PaymentCard(number: "9860123456789012")
        context.insert(card)
        card.person = ali
        try context.save()

        context.delete(ali)
        try context.save()

        let people = try context.fetch(FetchDescriptor<Person>())
        let entries = try context.fetch(FetchDescriptor<Entry>())
        let cards = try context.fetch(FetchDescriptor<PaymentCard>())

        #expect(people.count == 1)
        #expect(entries.count == 1)
        #expect(entries.first?.person?.name == "Bob")
        #expect(cards.isEmpty)
    }
}
