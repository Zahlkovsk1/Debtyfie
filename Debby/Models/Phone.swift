//
//  Phone.swift
//  Debby
//
//  Created by Shox on 19/10/26.
//

import Foundation

// MARK: - Countries

nonisolated struct CallingCountry: Identifiable, Hashable, Sendable {
    let region: String        // "UZ"
    let dialCode: String      // "998"

    var id: String { region }
    var displayCode: String { "+" + dialCode }
    var name: String { Locale.current.localizedString(forRegionCode: region) ?? region }

    /// 🇺🇿, built from the two-letter region code.
    var flag: String {
        region.uppercased().unicodeScalars
            .compactMap { UnicodeScalar(127397 + $0.value) }
            .map { String($0) }
            .joined()
    }
}

nonisolated extension CallingCountry {
    private static let dialCodes: [String: String] = [
        "UZ": "998", "RU": "7", "IT": "39", "KZ": "7", "KG": "996", "TJ": "992",
        "TM": "993", "AZ": "994", "GE": "995", "AM": "374", "UA": "380", "BY": "375",
        "MD": "373", "TR": "90", "AE": "971", "DE": "49", "FR": "33", "ES": "34",
        "GB": "44", "US": "1", "CA": "1", "PL": "48", "CH": "41", "AT": "43",
        "IL": "972", "CN": "86", "KR": "82", "IN": "91", "PK": "92", "AF": "93",
        "SA": "966", "QA": "974", "KW": "965", "JP": "81", "NL": "31", "BE": "32",
        "GR": "30", "CZ": "420", "SE": "46", "LT": "370", "LV": "371", "EE": "372",
        "RO": "40", "BG": "359"
    ]

    static let all: [CallingCountry] = dialCodes
        .map { CallingCountry(region: $0.key, dialCode: $0.value) }
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

    /// Shown first in the picker.
    static let frequent: [CallingCountry] = ["UZ", "RU", "IT", "KZ"].compactMap { country(region: $0) }

    static func country(region: String) -> CallingCountry? {
        dialCodes[region].map { CallingCountry(region: region, dialCode: $0) }
    }
}

// MARK: - Phone number

nonisolated struct PhoneNumber: Sendable {
    let country: CallingCountry
    /// Digits only, without the country code.
    let national: String

    init(country: CallingCountry, typed: String) {
        var digits = typed.filter { $0.isASCII && $0.isNumber }
        // In Russia and Kazakhstan people often type 8 or 7 first: 8 (900) 123-45-67
        if country.dialCode == "7", digits.count == 11, digits.first == "8" || digits.first == "7" {
            digits.removeFirst()
        }
        self.country = country
        self.national = digits
    }

    var internationalDigits: String { country.dialCode + national }
    var display: String { "\(country.displayCode) \(Self.grouped(national))" }
    var callURL: URL? { URL(string: "tel:+\(internationalDigits)") }
    var whatsAppURL: URL? { URL(string: "https://wa.me/\(internationalDigits)") }

    /// "901234567" → "901 234 567", "9001234567" → "900 123 4567"
    static func grouped(_ digits: String) -> String {
        var groups: [String] = []
        var rest = Substring(digits)
        while rest.count > 4 {
            groups.append(String(rest.prefix(3)))
            rest = rest.dropFirst(3)
        }
        if !rest.isEmpty { groups.append(String(rest)) }
        return groups.joined(separator: " ")
    }
}

// MARK: - Messengers

nonisolated extension Messenger {
    var displayName: String {
        switch self {
        case .telegram: "Telegram"
        case .whatsapp: "WhatsApp"
        }
    }

    /// The link that opens the chat in the installed app.
    /// Telegram: a username. WhatsApp: a phone number with country code.
    func url(for handle: String) -> URL? {
        switch self {
        case .telegram:
            let name = handle
                .trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: "@", with: "")
            guard !name.isEmpty else { return nil }
            return URL(string: "https://t.me/\(name)")
        case .whatsapp:
            let digits = handle.filter { $0.isASCII && $0.isNumber }
            guard !digits.isEmpty else { return nil }
            return URL(string: "https://wa.me/\(digits)")
        }
    }
}

// MARK: - Person

extension Person {
    var phone: PhoneNumber? {
        guard let phoneRegion, let phoneNumber, !phoneNumber.isEmpty,
              let country = CallingCountry.country(region: phoneRegion) else { return nil }
        return PhoneNumber(country: country, typed: phoneNumber)
    }

    var messengerURL: URL? {
        guard let messenger, let messengerHandle else { return nil }
        return messenger.url(for: messengerHandle)
    }
}
