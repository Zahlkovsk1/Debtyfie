//
//  PaymentCard.swift
//  Debby
//
//  Created by Shox on 19/10/26.
//

import Foundation
import SwiftData

nonisolated enum Bank: String, Codable, CaseIterable, Sendable {
    case sber, tbank

    var displayName: String {
        switch self {
        case .sber: "Sber"
        case .tbank: "T-Bank"
        }
    }
}

@Model
final class PaymentCard {
    var id: UUID
    var number: String          // digits only, no spaces
    var holderName: String
    var bank: Bank?
    var createdAt: Date
    var person: Person?

    init(number: String, holderName: String = "", bank: Bank? = nil) {
        self.id = UUID()
        self.number = number.filter { $0.isASCII && $0.isNumber }
        self.holderName = holderName
        self.bank = bank
        self.createdAt = .now
    }
}

extension PaymentCard {
    var network: CardNetwork? { CardNetwork(number: number) }
    var formattedNumber: String { CardNetwork.grouped(number) }
    var looksValid: Bool { CardNetwork.passesLuhnCheck(number) }
}
