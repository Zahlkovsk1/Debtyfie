//
//  StatisticsRates.swift
//  Debby
//
//  Created by Shox on 29/10/26.
//
import Foundation

/// An ordered pair of currencies, written "1 base = rate quote".
struct CurrencyPair: Hashable, Identifiable {
    let base: Currency
    let quote: Currency

    var id: String { base.code + "/" + quote.code }
}

/// Everything exchanged between one pair of currencies in a period.
struct RateSummary: Identifiable {
    let pair: CurrencyPair
    let operations: Int
    /// Total exchanged, in minor units of `pair.base` and `pair.quote`.
    let baseVolume: Int
    let quoteVolume: Int
    /// The rate of the most recent exchange, as typed (or flipped to the usual direction).
    let latest: Decimal
    let lowest: Decimal
    let highest: Decimal

    var id: String { pair.id }

    /// Volume-weighted average: total quote amount divided by total base amount.
    var average: Decimal {
        guard baseVolume > 0 else { return 0 }
        let ratio = Decimal(quoteVolume) / Decimal(baseVolume)
        let scale = Decimal(
            sign: .plus,
            exponent: pair.base.fractionDigits - pair.quote.fractionDigits,
            significand: 1
        )
        return ratio * scale
    }
}

/// Running totals for one currency pair while the entries are being read.
private struct RateAccumulator {
    var operations = 0
    var baseVolume = 0
    var quoteVolume = 0
    var latestDate: Date
    var latest: Decimal
    var lowest: Decimal
    var highest: Decimal
}

extension Sequence where Element == Entry {
    /// Summaries of the entries that have a second currency, one per currency pair,
    /// most-used pair first. Opposite directions of the same pair are merged.
    func rateSummaries(
        period: StatsPeriod,
        range: DayRange? = nil,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [RateSummary] {
        var byPair: [CurrencyPair: RateAccumulator] = [:]

        for entry in self where period.contains(entry.date, range: range, now: now, calendar: calendar) {
            guard let conversion = entry.conversion,
                  let counterMinor = entry.counterAmountMinor,
                  conversion.rate > 0 else { continue }

            // Always quote the stronger currency as the base (rate of 1 or more).
            let flipped = conversion.rate < 1
            let pair = flipped
                ? CurrencyPair(base: conversion.currency, quote: entry.currency)
                : CurrencyPair(base: entry.currency, quote: conversion.currency)
            let rate = flipped ? 1 / conversion.rate : conversion.rate
            let baseMinor = flipped ? counterMinor : entry.amountMinor
            let quoteMinor = flipped ? entry.amountMinor : counterMinor

            var item = byPair[pair] ?? RateAccumulator(
                latestDate: entry.date, latest: rate, lowest: rate, highest: rate
            )
            item.operations += 1
            item.baseVolume += baseMinor
            item.quoteVolume += quoteMinor
            item.lowest = Swift.min(item.lowest, rate)
            item.highest = Swift.max(item.highest, rate)
            if entry.date >= item.latestDate {
                item.latestDate = entry.date
                item.latest = rate
            }
            byPair[pair] = item
        }

        return byPair
            .map { pair, item in
                RateSummary(
                    pair: pair,
                    operations: item.operations,
                    baseVolume: item.baseVolume,
                    quoteVolume: item.quoteVolume,
                    latest: item.latest,
                    lowest: item.lowest,
                    highest: item.highest
                )
            }
            .sorted {
                if $0.operations != $1.operations { return $0.operations > $1.operations }
                return $0.id < $1.id
            }
    }
}
