//
//  AppStoreLocaleTests.swift
//
//  Tests for App Store Connect locale formatting logic.
//

import XCTest
@testable import xcparse

final class AppStoreLocaleTests: XCTestCase {

    // MARK: - appStoreLocale(language:region:)

    func testArabicSaudiArabia() {
        XCTAssertEqual(
            AttachmentExportOptions.appStoreLocale(language: "ar", region: "SA"),
            "ar-SA"
        )
    }

    func testGermanGermany() {
        XCTAssertEqual(
            AttachmentExportOptions.appStoreLocale(language: "de", region: "DE"),
            "de-DE"
        )
    }

    func testEnglishCanada() {
        XCTAssertEqual(
            AttachmentExportOptions.appStoreLocale(language: "en", region: "CA"),
            "en-CA"
        )
    }

    func testEnglishUnitedStates() {
        XCTAssertEqual(
            AttachmentExportOptions.appStoreLocale(language: "en", region: "US"),
            "en-US"
        )
    }

    func testSpanishSpain() {
        XCTAssertEqual(
            AttachmentExportOptions.appStoreLocale(language: "es", region: "ES"),
            "es-ES"
        )
    }

    func testLatinAmericanSpanishMexico() {
        // es-419 (Latin American Spanish) + MX region → es-MX
        XCTAssertEqual(
            AttachmentExportOptions.appStoreLocale(language: "es-419", region: "MX"),
            "es-MX"
        )
    }

    func testFrenchFrance() {
        XCTAssertEqual(
            AttachmentExportOptions.appStoreLocale(language: "fr", region: "FR"),
            "fr-FR"
        )
    }

    func testNorwegianBokmalMapsToNo() {
        // nb (Norwegian Bokmål) → "no" with no region suffix
        XCTAssertEqual(
            AttachmentExportOptions.appStoreLocale(language: "nb", region: "NO"),
            "no"
        )
    }

    func testDutchNetherlands() {
        XCTAssertEqual(
            AttachmentExportOptions.appStoreLocale(language: "nl", region: "NL"),
            "nl-NL"
        )
    }

    // MARK: - Edge cases

    func testLatinAmericanSpanishES() {
        // es-419 + ES region → es-ES
        XCTAssertEqual(
            AttachmentExportOptions.appStoreLocale(language: "es-419", region: "ES"),
            "es-ES"
        )
    }

    func testSimpleLanguagePassesThrough() {
        // A plain language code without subtag passes through unchanged
        XCTAssertEqual(
            AttachmentExportOptions.appStoreLocale(language: "ja", region: "JP"),
            "ja-JP"
        )
    }

    static var allTests = [
        ("testArabicSaudiArabia", testArabicSaudiArabia),
        ("testGermanGermany", testGermanGermany),
        ("testEnglishCanada", testEnglishCanada),
        ("testEnglishUnitedStates", testEnglishUnitedStates),
        ("testSpanishSpain", testSpanishSpain),
        ("testLatinAmericanSpanishMexico", testLatinAmericanSpanishMexico),
        ("testFrenchFrance", testFrenchFrance),
        ("testNorwegianBokmalMapsToNo", testNorwegianBokmalMapsToNo),
        ("testDutchNetherlands", testDutchNetherlands),
        ("testLatinAmericanSpanishES", testLatinAmericanSpanishES),
        ("testSimpleLanguagePassesThrough", testSimpleLanguagePassesThrough),
    ]
}
