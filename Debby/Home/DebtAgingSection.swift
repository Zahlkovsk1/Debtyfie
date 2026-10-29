//
//  DebtAgingSection.swift
//  Debby
//
//  Created by Shox on 23/10/26.
//

import SwiftUI
import SwiftData

struct DebtAgingSection: View {
    let people: [Person]
    let currency: Currency

    private var aging: DebtAging {
        people.debtAging(in: currency)
    }

    var body: some View {
        let data = aging

        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("How old the debts are")
                .font(.appTitle)
                .foregroundStyle(.textPrimary)

            if data.debts.isEmpty {
                Text("Nobody owes you in \(currency.code).")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            } else {
                buckets(data)

                Text("Follow up first")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                    .padding(.top, Spacing.s)

                followUp(data)
            }
        }
    }

    // MARK: Age groups

    private func buckets(_ data: DebtAging) -> some View {
        let groups = data.buckets
        let total = max(groups.reduce(0) { $0 + $1.total }, 1)

        return VStack(spacing: Spacing.m) {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    ForEach(groups.filter { $0.total > 0 }) { group in
                        Rectangle()
                            .fill(color(for: group.age))
                            .frame(width: geometry.size.width * Double(group.total) / Double(total))
                    }
                }
                .frame(width: geometry.size.width, alignment: .leading)
            }
            .frame(height: 10)
            .clipShape(Capsule())

            ForEach(groups) { group in
                HStack(spacing: Spacing.m) {
                    Circle()
                        .fill(color(for: group.age))
                        .frame(width: 10, height: 10)

                    Text(group.age.title)
                        .font(.appBody)
                        .foregroundStyle(.textPrimary)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(currency.formatted(minorUnits: group.total))
                            .font(.appHeadline)
                            .foregroundStyle(.textPrimary)
                        Text("^[\(group.count) person](inflect: true)")
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                    }
                }
            }
        }
        .padding(Spacing.m)
        .background(.surface, in: RoundedRectangle(cornerRadius: Radius.l))
    }

    private func color(for age: DebtAge) -> Color {
        switch age {
        case .fresh: Color.textSecondary.opacity(0.35)
        case .middle: Color.textSecondary
        case .old: Color.textPrimary
        }
    }

    // MARK: Who to call

    private func followUp(_ data: DebtAging) -> some View {
        VStack(spacing: Spacing.m) {
            ForEach(Array(data.debts.prefix(5))) { debt in
                NavigationLink(value: debt.person) {
                    HStack(spacing: Spacing.m) {
                        PersonAvatar(person: debt.person, size: 36)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(debt.person.name)
                                .font(.appBody)
                                .foregroundStyle(.textPrimary)
                                .lineLimit(1)
                            Text("^[\(debt.days) day](inflect: true) · since \(debt.since.formatted(.dateTime.day().month(.abbreviated)))")
                                .font(.appCaption)
                                .foregroundStyle(.textSecondary)
                        }

                        Spacer(minLength: Spacing.s)

                        Text(currency.formatted(minorUnits: debt.minorUnits))
                            .font(.appHeadline)
                            .foregroundStyle(.textPrimary)
                            .lineLimit(1)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.m)
        .background(.surface, in: RoundedRectangle(cornerRadius: Radius.l))
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            DebtAgingSection(people: PreviewData.people, currency: .eur)
                .padding(Spacing.m)
        }
        .navigationDestination(for: Person.self) { PersonDetailView(person: $0) }
    }
    .modelContainer(PreviewData.container)
}
