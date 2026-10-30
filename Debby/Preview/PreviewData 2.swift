//
//  PreviewData 2.swift
//  Debby
//
//  Created by Shox on 19/10/26.
//


#if DEBUG
import Foundation
import SwiftData

@MainActor
enum PreviewData {
    static var container: ModelContainer { sample.container }
    static var people: [Person] { sample.people }
    static var entries: [Entry] { people.flatMap(\.entries).sorted { $0.date > $1.date } }
    
    private static let sample: (container: ModelContainer, people: [Person]) = {
        let container = try! ModelContainer(
            for: Person.self, Entry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let gafur = Person(name: "Gafur Rakhimov")
        let ali = Person(name: "Ali Karimov")
        let baga = Person(name: "Baga")
        let nilufar = Person(name: "Nilufar")
        for person in [gafur, ali, baga, nilufar] { context.insert(person) }
        
        gafur.phoneRegion = "RU"
               gafur.phoneNumber = "9001234567"
               gafur.messenger = .whatsapp
               gafur.messengerHandle = "+7 900 123 45 67"

               ali.phoneRegion = "UZ"
               ali.phoneNumber = "901234567"
               ali.messenger = .telegram
               ali.messengerHandle = "ali_karimov"
               ali.note = "Brings dollars on Fridays. Prefers to be paid back in euros."

               let humo = PaymentCard(number: "9860123456789012", holderName: "ALI KARIMOV")
               let sber = PaymentCard(number: "2202123456789012", holderName: "ALI KARIMOV", bankName: "Sber")
               context.insert(humo)
               context.insert(sber)
               humo.person = ali
               sber.person = ali

        func add(_ entry: Entry, hoursAgo: Double) {
                   let moment = Date.now.addingTimeInterval(-hoursAgo * 3600)
                   entry.date = moment
                   entry.createdAt = moment
                   context.insert(entry)
               }

        // Gafur owes you 1.400 €
        add(Entry(person: gafur, direction: .gave, amount: 1_400, currency: .eur), hoursAgo: 72)

        // Ali brought 10.000 $, you will repay in euros at 0,92 → you owe him 9.200 €
        add(Entry(person: ali, direction: .received, amount: 10_000, currency: .usd,
                  conversion: Conversion(currency: .eur, amount: 9_200,
                                         rate: Decimal(string: "0.92")!)), hoursAgo: 2)

        // Baga: 500 € in, 500 € out → settled in euros; plus 300 $ lent
        add(Entry(person: baga, direction: .received, amount: 500, currency: .eur), hoursAgo: 30)
        add(Entry(person: baga, direction: .gave, amount: 500, currency: .eur), hoursAgo: 26)
        add(Entry(person: baga, direction: .gave, amount: 300, currency: .usd), hoursAgo: 25)

        // Nilufar has no entries at all
        return (container, [gafur, ali, baga, nilufar])
    }()
}
#endif
