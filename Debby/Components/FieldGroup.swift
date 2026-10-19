//
//  FieldGroup.swift
//  Debby
//
//  Created by Shox on 19/10/26.
//
import SwiftUI

/// A small grey label above a block of form content.
struct FieldGroup<Content: View>: View {
    private let title: LocalizedStringKey
    private let content: Content

    init(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(title)
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension View {
    /// The flat grey rounded box all form fields sit in.
    func fieldStyle() -> some View {
        self
            .padding(Spacing.m)
            .background(.surface, in: RoundedRectangle(cornerRadius: Radius.m))
    }
}
