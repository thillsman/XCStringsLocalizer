import Foundation

// MARK: - XCStrings Models

/// Root structure of an .xcstrings file
struct XCStringsFile: Codable {
    var sourceLanguage: String
    var strings: [String: StringEntry]
    var version: String?

    enum CodingKeys: String, CodingKey {
        case sourceLanguage
        case strings
        case version
    }
}

/// A single string entry in the xcstrings file
struct StringEntry: Codable {
    var comment: String?
    var shouldTranslate: Bool?
    var localizations: [String: Localization]?

    enum CodingKeys: String, CodingKey {
        case comment
        case shouldTranslate
        case localizations
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
        shouldTranslate = try container.decodeIfPresent(Bool.self, forKey: .shouldTranslate)
        localizations = try container.decodeIfPresent([String: Localization].self, forKey: .localizations)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(comment, forKey: .comment)
        try container.encodeIfPresent(shouldTranslate, forKey: .shouldTranslate)
        try container.encodeIfPresent(localizations, forKey: .localizations)
    }
}

/// Localization for a specific language
struct Localization: Codable {
    var stringUnit: StringUnit?
    var variations: LocalizationVariations?

    enum CodingKeys: String, CodingKey {
        case stringUnit
        case variations
    }
}

/// The actual translated string with its state
struct StringUnit: Codable {
    var state: TranslationState
    var value: String

    enum CodingKeys: String, CodingKey {
        case state
        case value
    }
}

/// State of a translation
enum TranslationState: String, Codable {
    case new
    case translated
    case needsReview = "needs_review"
    case stale
}

/// Variations for plural/device-specific strings
struct LocalizationVariations: Codable {
    var plural: [String: StringUnit]?
    var device: [String: StringUnit]?
}

// MARK: - Statistics

/// Statistics about the translation operation
struct TranslationStats {
    var totalKeys: Int = 0
    var skippedShouldNotTranslate: Int = 0
    var skippedAlreadyTranslated: Int = 0
    var translated: Int = 0
    var errors: Int = 0

    mutating func reset() {
        totalKeys = 0
        skippedShouldNotTranslate = 0
        skippedAlreadyTranslated = 0
        translated = 0
        errors = 0
    }

    func summary() -> String {
        """

        ┌─────────────────────────────────────┬────────┐
        │ Translation Summary                 │        │
        ├─────────────────────────────────────┼────────┤
        │ Total keys                          │ \(String(format: "%6d", totalKeys)) │
        │ Translations created                │ \(String(format: "%6d", translated)) │
        │ Skipped (shouldTranslate=false)     │ \(String(format: "%6d", skippedShouldNotTranslate)) │
        │ Skipped (already translated)        │ \(String(format: "%6d", skippedAlreadyTranslated)) │
        │ Errors                              │ \(String(format: "%6d", errors)) │
        └─────────────────────────────────────┴────────┘
        """
    }
}

// MARK: - Translation Suggestions

/// A suggestion for improving an existing translation
struct TranslationSuggestion: Codable {
    let key: String
    let language: String
    let currentTranslation: String
    let suggestedTranslation: String
    let confidence: Int  // 1-5 scale
    let reasoning: String
}
