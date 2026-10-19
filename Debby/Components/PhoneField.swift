//
//  PhoneField.swift
//  Debby
//
//  Created by Shox on 19/10/26.
//
import SwiftUI

struct PhoneField: View {
    @Binding var country: CallingCountry
    @Binding var number: String
    @State private var isPickerShown = false

    var body: some View {
        HStack(spacing: Spacing.m) {
            Button {
                isPickerShown = true
            } label: {
                HStack(spacing: Spacing.xs) {
                    Text(country.flag)
                    Text(country.displayCode)
                        .font(.appBody)
                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.bold))
                }
                .foregroundStyle(.textPrimary)
            }
            .buttonStyle(.plain)

            Rectangle()
                .fill(.divider)
                .frame(width: 1, height: 24)

            TextField("Phone number", text: $number)
                .font(.appBody)
                .keyboardType(.phonePad)
        }
        .fieldStyle()
        .sheet(isPresented: $isPickerShown) {
            CountryPicker(selection: $country)
                .presentationDetents([.medium, .large])
        }
    }
}

#Preview {
    @Previewable @State var country = CallingCountry.country(region: "UZ")!
    @Previewable @State var number = ""
    PhoneField(country: $country, number: $number)
        .padding(Spacing.m)
}
