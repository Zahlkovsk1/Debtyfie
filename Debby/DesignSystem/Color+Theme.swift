//
//  Color+Theme.swift
//  Debby
//
//  Created by Shox on 18/10/26.
//

import SwiftUI
import UIKit

extension ShapeStyle where Self == Color {
    // MARK: Backgrounds
    /// Main screen background — pure white / pure black
    static var appBackground: Color { Color(light: .white, dark: .black) }
    /// Cards, input fields, list rows that need separation
    static var surface: Color { Color(light: Color(white: 0.96), dark: Color(white: 0.11)) }

    // MARK: Text
    /// Main text and primary buttons — near-black, not pure black (softer on the eye)
    static var textPrimary: Color { Color(light: Color(white: 0.04), dark: .white) }
    /// Captions, dates, "owes you" labels
    static var textSecondary: Color { Color(light: Color(white: 0.45), dark: Color(white: 0.6)) }

    // MARK: Lines
    static var divider: Color { Color(light: Color(white: 0.9), dark: Color(white: 0.18)) }

    // MARK: Money direction (the only colors in the app)
    /// Someone owes you
    static var positive: Color { Color(red: 0.13, green: 0.62, blue: 0.36) }
    /// You owe someone
    static var negative: Color { Color(red: 0.86, green: 0.24, blue: 0.22) }
}

// MARK: - Light/Dark helper
private extension Color {
    /// Builds a color that automatically switches with the system appearance.
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

// MARK: - Preview
#Preview {
    let swatches: [(String, Color)] = [
        ("appBackground", .appBackground),
        ("surface", .surface),
        ("textPrimary", .textPrimary),
        ("textSecondary", .textSecondary),
        ("divider", .divider),
        ("positive", .positive),
        ("negative", .negative)
    ]
    return List(swatches, id: \.0) { name, color in
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(width: 44, height: 44)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.divider))
            Text(name)
        }
    }
}
