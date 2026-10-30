//
//  PersonEditTests.swift
//  DebbyTests
//
//  Created by Shox on 19/10/26.
//

import Testing
import Foundation
import SwiftData
@testable import Debby

@MainActor
struct PersonEditTests {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    init() throws {
        container = try ModelContainer(
            for: Person.self, Entry.self, PaymentCard.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    @Test func renamingKeepsEntriesAndBalance() throws {
        let ali = Person(name: "Ali")
        context.insert(ali)
        context.insert(Entry(person: ali, direction: .gave, amount: 100, currency: .eur))

        ali.name = "Alisher"
        try context.save()

        #expect(ali.entries.count == 1)
        #expect(ali.balance(in: .eur) == 100)
    }

    @Test func deletingOneCardKeepsThePersonAndTheOtherCard() throws {
        let ali = Person(name: "Ali")
        context.insert(ali)
        context.insert(Entry(person: ali, direction: .gave, amount: 100, currency: .eur))

        let humo = PaymentCard(number: "9860123412341234", holderName: "ALI")
        let mir = PaymentCard(number: "2200123412341234", holderName: "ALI")
        context.insert(humo)
        context.insert(mir)
        humo.person = ali
        mir.person = ali
        try context.save()
        #expect(ali.cards.count == 2)

        context.delete(humo)
        try context.save()

        #expect(ali.cards.count == 1)
        #expect(ali.cards.first?.number == "2200123412341234")
        #expect(ali.entries.count == 1)
    }
}
