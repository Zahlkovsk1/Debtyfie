//
//  PhoneTests 2.swift
//  Debby
//
//  Created by Shox on 19/10/26.
//


import Testing
import Foundation
@testable import Debby

struct PhoneTests {
    let uz = CallingCountry.country(region: "UZ")!
    let ru = CallingCountry.country(region: "RU")!
    let kz = CallingCountry.country(region: "KZ")!
    let it = CallingCountry.country(region: "IT")!

    @Test func uzbekNumberDisplay() {
        let phone = PhoneNumber(country: uz, typed: "90 123 45 67")
        #expect(phone.national == "901234567")
        #expect(phone.display == "+998 901 234 567")
    }

    @Test func callAndWhatsAppLinks() {
        let phone = PhoneNumber(country: uz, typed: "901234567")
        #expect(phone.callURL?.absoluteString == "tel:+998901234567")
        #expect(phone.whatsAppURL?.absoluteString == "https://wa.me/998901234567")
    }

    @Test func russianLeadingEightIsDropped() {
        let phone = PhoneNumber(country: ru, typed: "8 (900) 123-45-67")
        #expect(phone.national == "9001234567")
        #expect(phone.display == "+7 900 123 4567")
        #expect(phone.internationalDigits == "79001234567")
    }

    @Test func russianNumberWithoutPrefixIsUntouched() {
        #expect(PhoneNumber(country: ru, typed: "900 123 45 67").national == "9001234567")
    }

    @Test func italianLeadingZeroIsKept() {
        // Italian landlines really start with 0
        #expect(PhoneNumber(country: it, typed: "031 123456").national == "031123456")
    }

    @Test func russiaAndKazakhstanShareACodeButNotARegion() {
        #expect(ru.dialCode == kz.dialCode)
        #expect(ru.id != kz.id)
    }

    @Test func countryTable() {
        #expect(CallingCountry.frequent.map(\.region) == ["UZ", "RU", "IT", "KZ"])
        #expect(CallingCountry.country(region: "XX") == nil)
        #expect(Set(CallingCountry.all.map(\.region)).count == CallingCountry.all.count)
        #expect(uz.flag == "🇺🇿")
        #expect(uz.displayCode == "+998")
    }

    @Test func telegramLinks() {
        #expect(Messenger.telegram.url(for: "@shox_m")?.absoluteString == "https://t.me/shox_m")
        #expect(Messenger.telegram.url(for: "  shox_m ")?.absoluteString == "https://t.me/shox_m")
        #expect(Messenger.telegram.url(for: "") == nil)
    }

    @Test func whatsAppLinksUseOnlyDigits() {
        #expect(Messenger.whatsapp.url(for: "+39 333 123 4567")?.absoluteString == "https://wa.me/393331234567")
        #expect(Messenger.whatsapp.url(for: "abc") == nil)
    }
}