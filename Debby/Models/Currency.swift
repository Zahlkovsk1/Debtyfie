//
//  Currency.swift
//  Debby
//
//  Created by Shox on 18/10/26.
//

import SwiftUI

nonisolated struct Currency :  Hashable, Codable, Identifiable, Sendable {
    let code: String
    var id: String { code }
    
    init(code: String) {
        self.code = code.uppercased()
    }
}

nonisolated extension Currency {
      static let eur = Currency(code: "EUR")
      static let usd = Currency(code: "USD")
      static let rub = Currency(code: "RUB")
      static let uzs = Currency(code: "UZS")
    
    var name: String {
        Locale.current.localizedString(forCurrencyCode: code) ?? code
    }
    
    // How many decimals this currency uses: 2 for EUR, 0 for JPY, 3 for KWD
       var fractionDigits: Int {
           let formatter = NumberFormatter()
           formatter.numberStyle = .currency
           formatter.currencyCode = code
           return formatter.maximumFractionDigits
       }
    
    var flag: String {
        if code == "EUR" { return "🇪🇺" }
        let country = String(code.prefix(2))
        guard Self.validRegions.contains(country) else { return "💱" }
        let regionalIndicatorOffset: UInt32 = 127397   // "A" (65) → 🇦 (127462)
        return country.unicodeScalars
            .compactMap { UnicodeScalar(regionalIndicatorOffset + $0.value) }
            .map { String($0) }
            .joined()
    }
    
    
    private static let validRegions: Set<String> =
        Set(Locale.Region.isoRegions.map(\.identifier))
    
    static let supported: [Currency] = [
        "EUR", "USD", "RUB", "UZS", "GBP", "CHF", "TRY", "AED", "KZT", "KGS",
        "TJS", "TMT", "AZN", "GEL", "AMD", "UAH", "BYN", "MDL", "PLN", "CZK",
        "SEK", "NOK", "DKK", "CNY", "JPY", "KRW", "INR", "PKR", "AFN", "SAR",
        "QAR", "KWD", "ILS", "CAD", "AUD"
    ]
    .map(Currency.init(code:))
    .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
}

//#Preview {
//    List(Currency.supported) { currency in
//        HStack {
//            Text(currency.flag)
//            Text(currency.code).font(.appHeadline)
//            Text(currency.name).foregroundStyle(.textSecondary)
//            Spacer()
//            Text("\(currency.fractionDigits)").font(.appAmount)
//        }
//    }
//}



#Preview("Flag test") {
    Text("🇪🇺 🇺🇸 🇯🇵 \(Currency.usd.flag)")
        .font(.largeTitle)
}
