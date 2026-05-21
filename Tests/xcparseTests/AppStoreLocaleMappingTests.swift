//
//  AppStoreLocaleMappingTests.swift
//
//  Tests for locale code normalization to App Store Connect API format.
//  See: https://github.com/ChargePoint/xcparse/issues/89
//

import XCTest
@testable import xcparse

final class AppStoreLocaleMappingTests: XCTestCase {

    // MARK: - normalize(language:region:) tests

    func testArabicSaudiArabia() {
        // ar(SA) -> ar-SA
        XCTAssertEqual(AppStoreLocaleMapping.normalize(language: "ar", region: "SA"), "ar-SA")
    }

    func testGermanGermany() {
        // de(DE) -> de-DE
        XCTAssertEqual(AppStoreLocaleMapping.normalize(language: "de", region: "DE"), "de-DE")
    }

    func testEnglishCanada() {
        // en(CA) -> en-CA
        XCTAssertEqual(AppStoreLocaleMapping.normalize(language: "en", region: "CA"), "en-CA")
    }

    func testEnglishUnitedStates() {
        // en(US) -> en-US
        XCTAssertEqual(AppStoreLocaleMapping.normalize(language: "en", region: "US"), "en-US")
    }

    func testSpanishSpain() {
        // es(ES) -> es-ES
        XCTAssertEqual(AppStoreLocaleMapping.normalize(language: "es", region: "ES"), "es-ES")
    }

    func testSpanishLatinAmericaMexico() {
        // es-419(MX) -> es-MX
        XCTAssertEqual(AppStoreLocaleMapping.normalize(language: "es-419", region: "MX"), "es-MX")
    }

    func testFrenchFrance() {
        // fr(FR) -> fr-FR
        XCTAssertEqual(AppStoreLocaleMapping.normalize(language: "fr", region: "FR"), "fr-FR")
    }

    func testNorwegianBokmal() {
        // nb(NO) -> no (special override, ignores region)
        XCTAssertEqual(AppStoreLocaleMapping.normalize(language: "nb", region: "NO"), "no")
    }

    func testDutchNetherlands() {
        // nl(NL) -> nl-NL
        XCTAssertEqual(AppStoreLocaleMapping.normalize(language: "nl", region: "NL"), "nl-NL")
    }

    // MARK: - Edge cases

    func testLanguageOnlyNoRegion() {
        XCTAssertEqual(AppStoreLocaleMapping.normalize(language: "en", region: nil), "en")
    }

    func testNorwegianBokmalNoRegion() {
        // nb without region should still map to "no"
        XCTAssertEqual(AppStoreLocaleMapping.normalize(language: "nb", region: nil), "no")
    }

    func testCompoundLanguageCodeNoRegion() {
        // es-419 without region should stay as es-419
        XCTAssertEqual(AppStoreLocaleMapping.normalize(language: "es-419", region: nil), "es-419")
    }

    func testChineseSimplifiedPreservesScriptSubtag() {
        // zh-Hans should be preserved (script subtag, not area code)
        XCTAssertEqual(AppStoreLocaleMapping.normalize(language: "zh-Hans", region: "CN"), "zh-Hans")
    }

    func testChineseTraditionalPreservesScriptSubtag() {
        // zh-Hant should be preserved (script subtag, not area code)
        XCTAssertEqual(AppStoreLocaleMapping.normalize(language: "zh-Hant", region: "TW"), "zh-Hant")
    }

    func testChineseSimplifiedNoRegion() {
        XCTAssertEqual(AppStoreLocaleMapping.normalize(language: "zh-Hans", region: nil), "zh-Hans")
    }

    // MARK: - normalizeDirectoryName tests

    func testNormalizeDirectoryNameNilLanguage() {
        XCTAssertNil(AppStoreLocaleMapping.normalizeDirectoryName(language: nil, region: "US"))
    }

    func testNormalizeDirectoryNameWithLanguageAndRegion() {
        XCTAssertEqual(AppStoreLocaleMapping.normalizeDirectoryName(language: "en", region: "US"), "en-US")
    }

    func testNormalizeDirectoryNameWithLanguageOnly() {
        XCTAssertEqual(AppStoreLocaleMapping.normalizeDirectoryName(language: "en", region: nil), "en")
    }

    // MARK: - All issue #89 mappings at once

    func testAllIssueMappings() {
        let mappings: [(language: String, region: String, expected: String)] = [
            ("ar", "SA", "ar-SA"),
            ("de", "DE", "de-DE"),
            ("en", "CA", "en-CA"),
            ("en", "US", "en-US"),
            ("es", "ES", "es-ES"),
            ("es-419", "MX", "es-MX"),
            ("fr", "FR", "fr-FR"),
            ("nb", "NO", "no"),
            ("nl", "NL", "nl-NL"),
        ]

        for mapping in mappings {
            let result = AppStoreLocaleMapping.normalize(language: mapping.language, region: mapping.region)
            XCTAssertEqual(result, mapping.expected,
                           "Expected \(mapping.language)(\(mapping.region)) -> \(mapping.expected), got \(result)")
        }
    }

    static var allTests = [
        ("testArabicSaudiArabia", testArabicSaudiArabia),
        ("testGermanGermany", testGermanGermany),
        ("testEnglishCanada", testEnglishCanada),
        ("testEnglishUnitedStates", testEnglishUnitedStates),
        ("testSpanishSpain", testSpanishSpain),
        ("testSpanishLatinAmericaMexico", testSpanishLatinAmericaMexico),
        ("testFrenchFrance", testFrenchFrance),
        ("testNorwegianBokmal", testNorwegianBokmal),
        ("testDutchNetherlands", testDutchNetherlands),
        ("testLanguageOnlyNoRegion", testLanguageOnlyNoRegion),
        ("testNorwegianBokmalNoRegion", testNorwegianBokmalNoRegion),
        ("testCompoundLanguageCodeNoRegion", testCompoundLanguageCodeNoRegion),
        ("testChineseSimplifiedPreservesScriptSubtag", testChineseSimplifiedPreservesScriptSubtag),
        ("testChineseTraditionalPreservesScriptSubtag", testChineseTraditionalPreservesScriptSubtag),
        ("testChineseSimplifiedNoRegion", testChineseSimplifiedNoRegion),
        ("testNormalizeDirectoryNameNilLanguage", testNormalizeDirectoryNameNilLanguage),
        ("testNormalizeDirectoryNameWithLanguageAndRegion", testNormalizeDirectoryNameWithLanguageAndRegion),
        ("testNormalizeDirectoryNameWithLanguageOnly", testNormalizeDirectoryNameWithLanguageOnly),
        ("testAllIssueMappings", testAllIssueMappings),
    ]
}
