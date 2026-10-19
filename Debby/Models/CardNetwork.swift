//
//  CardNetwork.swift
//  Debby
//
//  Created by Shox on 19/10/26.
//

import Foundation

nonisolated enum CardNetwork: String, Codable, CaseIterable, Sendable {
    case humo, uzcard, mir, visa, mastercard

    /// Works out the network from the first digits of a card number.
    /// Returns nil until enough digits are typed to be sure.
    init?(number: String) {
        let digits = number.filter { $0.isASCII && $0.isNumber }

        func prefix(_ length: Int) -> Int? {
            digits.count >= length ? Int(digits.prefix(length)) : nil
        }

        if let four = prefix(4) {
            switch four {
            case 9860: self = .humo; return
            case 8600: self = .uzcard; return
            case 2200...2204: self = .mir; return
            case 2221...2720: self = .mastercard; return
            default: break
            }
        }
        if let two = prefix(2), (51...55).contains(two) {
            self = .mastercard
            return
        }
        if digits.first == "4" {
            self = .visa
            return
        }
        return nil
    }

    var displayName: String {
        switch self {
        case .humo: "HUMO"
        case .uzcard: "UZCARD"
        case .mir: "MIR"
        case .visa: "VISA"
        case .mastercard: "Mastercard"
        }
    }
}

nonisolated extension CardNetwork {
    /// "8600123456789012" → "8600 1234 5678 9012"
    static func grouped(_ digits: String) -> String {
        stride(from: 0, to: digits.count, by: 4)
            .map { start -> String in
                let from = digits.index(digits.startIndex, offsetBy: start)
                let to = digits.index(from, offsetBy: 4, limitedBy: digits.endIndex) ?? digits.endIndex
                return String(digits[from..<to])
            }
            .joined(separator: " ")
    }

    /// The Luhn check: the checksum built into every real card number.
    /// It catches a mistyped digit or two swapped neighbours.
    static func passesLuhnCheck(_ number: String) -> Bool {
        let digits = number.filter { $0.isASCII && $0.isNumber }.compactMap(\.wholeNumberValue)
        guard digits.count >= 12 else { return false }

        var sum = 0
        for (index, digit) in digits.reversed().enumerated() {
            if index % 2 == 1 {
                let doubled = digit * 2
                sum += doubled > 9 ? doubled - 9 : doubled
            } else {
                sum += digit
            }
        }
        return sum % 10 == 0
    }
}
