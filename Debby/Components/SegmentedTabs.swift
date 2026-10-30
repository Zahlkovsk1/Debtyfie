//
//  SegmentedTabs.swift
//  Debby
//
//  Created by Shox on 30/10/26.
//

import SwiftUI

/// A tall two-or-more option switch with a sliding pill under the selected option.
struct SegmentedTabs<Value: Hashable>: View {
    @Binding var selection: Value
    let options: [Value]
    let title: (Value) -> LocalizedStringKey

    @Namespace private var pill

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection

                Button {
                    withAnimation(.snappy(duration: 0.25)) { selection = option }
                } label: {
                    Text(title(option))
                        .font(.appHeadline)
                        .foregroundStyle(isSelected ? Color.textPrimary : Color.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(Color.appBackground)
                                    .shadow(color: .black.opacity(0.08), radius: 4, y: 1)
                                    .matchedGeometryEffect(id: "pill", in: pill)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Color.surface, in: Capsule())
    }
}

#Preview {
    @Previewable @State var side = OwedSide.owedToYou

    SegmentedTabs(selection: $side, options: [.owedToYou, .youOwe]) { side -> LocalizedStringKey in
        switch side {
        case .owedToYou: "Owed to you"
        case .youOwe: "You owe"
        }
    }
    .padding(Spacing.m)
}
