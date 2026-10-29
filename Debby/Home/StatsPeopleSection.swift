//
//  StatsPeopleSection.swift
//  Debby
//
//  Created by Shox on 29/10/26.
//
import SwiftUI
import SwiftData

struct StatsPeopleSection: View {
    let people: [Person]
    let currency: Currency

    @State private var side = OwedSide.owedToYou

    private let limit = 5

    private var aging: DebtAging {
        people.debtAging(side, in: currency)
    }

    var body: some View {
        let data = aging

        VStack(alignment: .leading, spacing: Spacing.l) {
            peopleBlock(data)
            if !data.debts.isEmpty {
                agingBlock(data)
            }
        }
    }

    // MARK: People

    private func peopleBlock(_ data: DebtAging) -> some View {
        let rows = data.biggest(limit: limit)

        return VStack(alignment: .leading, spacing: Spacing.s) {
            HStack {
                Text("People")
                    .font(.appTitle)
                    .foregroundStyle(.textPrimary)
                Spacer(minLength: Spacing.m)
                Picker("Side", selection: $side) {
                    Text("Owed to you").tag(OwedSide.owedToYou)
                    Text("You owe").tag(OwedSide.youOwe)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 240)
            }

            if rows.isEmpty {
                emptyText
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                    .padding(.top, Spacing.xs)
            } else {
                VStack(spacing: 0) {
                    ForEach(rows) { debt in
                        NavigationLink(value: debt.person) {
                            row(debt)
                        }
                        .buttonStyle(.plain)

                        Rectangle()
                            .fill(.divider)
                            .frame(height: 1)
                    }
                }

                if data.debts.count > limit {
                    NavigationLink {
                        OwedView()
                    } label: {
                        HStack(spacing: Spacing.xs) {
                            Text("See all")
                            Image(systemName: "chevron.right")
                        }
                        .font(.appBody)
                        .foregroundStyle(.textSecondary)
                        .padding(.top, Spacing.xs)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var emptyText: some View {
        switch side {
        case .owedToYou: Text("Nobody owes you in \(currency.code).")
        case .youOwe: Text("You owe nobody in \(currency.code).")
        }
    }

    private func row(_ debt: AgedDebt) -> some View {
        HStack(spacing: Spacing.m) {
            PersonAvatar(person: debt.person, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.s) {
                    Text(debt.person.name)
                        .font(.appHeadline)
                        .foregroundStyle(.textPrimary)
                        .lineLimit(1)
                    if side == .owedToYou && debt.needsFollowUp {
                        followUpBadge
                    }
                }
                Text("^[\(debt.days) day](inflect: true) · since \(debt.since.formatted(.dateTime.day().month(.abbreviated)))")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            }

            Spacer(minLength: Spacing.s)

            Text(amountText(debt.minorUnits))
                .font(.appHeadline)
                .foregroundStyle(side == .owedToYou ? Color.positive : Color.textPrimary)
                .lineLimit(1)
        }
        .padding(.vertical, Spacing.s)
        .contentShape(Rectangle())
    }

    private var followUpBadge: some View {
        Text("Follow up")
            .font(.appCaption)
            .foregroundStyle(.appBackground)
            .padding(.horizontal, Spacing.s)
            .padding(.vertical, 2)
            .background(.textPrimary, in: Capsule())
    }

    // MARK: Age groups

    private func agingBlock(_ data: DebtAging) -> some View {
        let groups = data.buckets
        let total = max(groups.reduce(0) { $0 + $1.total }, 1)

        return VStack(alignment: .leading, spacing: Spacing.s) {
            agingTitle
                .font(.appTitle)
                .foregroundStyle(.textPrimary)

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
            .padding(.vertical, Spacing.xs)

            VStack(spacing: 0) {
                ForEach(groups) { group in
                    HStack(spacing: Spacing.m) {
                        Circle()
                            .fill(color(for: group.age))
                            .frame(width: 8, height: 8)

                        Text(group.age.title)
                            .font(.appBody)
                            .foregroundStyle(group.count > 0 ? Color.textPrimary : Color.textSecondary)

                        Spacer()

                        if group.count > 0 {
                            Text("\(compact(group.total)) · \(group.count)")
                                .font(.appHeadline)
                                .foregroundStyle(.textPrimary)
                        } else {
                            Text("—")
                                .font(.appBody)
                                .foregroundStyle(.textSecondary)
                        }
                    }
                    .padding(.vertical, Spacing.s)

                    Rectangle()
                        .fill(.divider)
                        .frame(height: 1)
                }
            }
        }
    }

    @ViewBuilder
    private var agingTitle: some View {
        switch side {
        case .owedToYou: Text("How old the debts are")
        case .youOwe: Text("How long you've owed")
        }
    }

    private func color(for age: DebtAge) -> Color {
        switch age {
        case .fresh: Color.textSecondary.opacity(0.35)
        case .middle: Color.textSecondary
        case .old: Color.textPrimary
        }
    }

    // MARK: Text helpers

    private func compact(_ minorUnits: Int) -> String {
        AmountParts(
            currency.formatted(minorUnits: minorUnits),
            fractionDigits: currency.fractionDigits
        ).compact
    }

    private func amountText(_ minorUnits: Int) -> String {
        (side == .owedToYou ? "+" : "−") + compact(minorUnits)
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            StatsPeopleSection(people: PreviewData.people, currency: .eur)
                .padding(Spacing.m)
        }
        .navigationDestination(for: Person.self) { PersonDetailView(person: $0) }
    }
    .modelContainer(PreviewData.container)
}
