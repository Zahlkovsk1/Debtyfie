//
//  AmountParser 2.swift
//  Debby
//
//  Created by Shox on 19/10/26.
//

import Foundation

nonisolated enum AmountParser {
    /// "1500", "12,50", "12.50", ".5" → a number. Anything else → nil.
    /// One comma or one dot counts as the decimal separator. Two of them are
    /// ambiguous ("1.234,56"), so we refuse them instead of guessing.
    static func parse(_ text: String) -> Decimal? {
        let compact = text.filter { !$0.isWhitespace }
        guard !compact.isEmpty else { return nil }

        let separators = compact.filter { $0 == "." || $0 == "," }
        guard separators.count <= 1 else { return nil }

        let normalized = compact.replacingOccurrences(of: ",", with: ".")
        guard normalized.allSatisfy({ $0.isASCII && ($0.isNumber || $0 == ".") }),
              normalized.contains(where: \.isNumber) else { return nil }

        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
    }

    /// Cuts off digits beyond what the currency has: 12,567 → 12,56 for euros, 12 for yen.
    /// A trailing separator is kept while the user is still typing ("12,").
    static func limitingDecimals(_ text: String, to digits: Int) -> String {
        guard let separator = text.firstIndex(where: { $0 == "." || $0 == "," }) else { return text }
        if digits == 0 { return String(text[..<separator]) }
        let decimals = text[text.index(after: separator)...]
        return String(text[...separator]) + String(decimals.prefix(digits))
    }
}
