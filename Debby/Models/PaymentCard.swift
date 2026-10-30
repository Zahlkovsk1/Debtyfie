//
//  PaymentCard.swift
//  Debby
//
//  Created by Shox on 19/10/26.
//

import Foundation
import SwiftData

@Model
final class PaymentCard {
    var id: UUID
    var number: String          // digits only, no spaces
    var holderName: String
    var bankName: String = ""   // free text, empty when not given
    var createdAt: Date
    var person: Person?

    init(number: String, holderName: String = "", bankName: String = "") {
        self.id = UUID()
        self.number = number.filter { $0.isASCII && $0.isNumber }
        self.holderName = holderName
        self.bankName = bankName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.createdAt = .now
    }
}

extension PaymentCard {
    var network: CardNetwork? { CardNetwork(number: number) }
    var formattedNumber: String { CardNetwork.grouped(number) }
    var looksValid: Bool { CardNetwork.passesLuhnCheck(number) }
}
