//
//  CardNetworkTests.swift
//  DebbyTests
//
//  Created by Shox on 19/10/26.
//

import Testing
@testable import Debby

struct CardNetworkTests {
    @Test func uzbekCards() {
        #expect(CardNetwork(number: "8600 1234") == .uzcard)
        #expect(CardNetwork(number: "9860") == .humo)
    }

    @Test func mirCardsStartWith2200To2204() {
        #expect(CardNetwork(number: "2200") == .mir)
        #expect(CardNetwork(number: "2204 99") == .mir)
    }

    @Test func mastercardRanges() {
        #expect(CardNetwork(number: "5555") == .mastercard)   // 51–55
        #expect(CardNetwork(number: "51") == .mastercard)
        #expect(CardNetwork(number: "2221") == .mastercard)   // 2221–2720
        #expect(CardNetwork(number: "2720") == .mastercard)
        #expect(CardNetwork(number: "2721") == nil)
        #expect(CardNetwork(number: "2205") == nil)           // between Mir and Mastercard
    }

    @Test func visaStartsWithFour() {
        #expect(CardNetwork(number: "4") == .visa)
        #expect(CardNetwork(number: "4111 1111") == .visa)
    }

    @Test func tooFewDigitsMeansUnknown() {
        #expect(CardNetwork(number: "86") == nil)
        #expect(CardNetwork(number: "5") == nil)
        #expect(CardNetwork(number: "") == nil)
    }

    @Test func spacesAndDashesAreIgnored() {
        #expect(CardNetwork(number: "8600-1234-5678") == .uzcard)
    }

    @Test func groupsInFours() {
        #expect(CardNetwork.grouped("8600123456789012") == "8600 1234 5678 9012")
        #expect(CardNetwork.grouped("123456789012345") == "1234 5678 9012 345")
        #expect(CardNetwork.grouped("") == "")
    }

    @Test func checksumAcceptsRealNumbers() {
        #expect(CardNetwork.passesLuhnCheck("4111 1111 1111 1111"))
        #expect(CardNetwork.passesLuhnCheck("5555555555554444"))
    }

    @Test func checksumCatchesTypos() {
        #expect(!CardNetwork.passesLuhnCheck("4111 1111 1111 1112"))   // one digit off
        #expect(!CardNetwork.passesLuhnCheck("4111 1111 1111 1151"))   // swapped/changed digit
        #expect(!CardNetwork.passesLuhnCheck("1234"))                  // too short
    }
}
