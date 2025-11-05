import Foundation
import ArgumentParser

// MARK: - CLI Entry Point

@main
struct XCStringsLocalizerCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "xcstrings-localizer",
        abstract: "Localize Xcode .xcstrings files using AI translation",
        discussion: """
        This tool reads an .xcstrings file and automatically translates strings to all target
        languages defined in the file. It respects translation settings, comments, and existing
        translations.

        FEATURES:
        • Automatic translation to all target languages
        • Respects shouldTranslate flags
        • Uses comments for translation context
        • Skips already translated strings (unless --force)
        • Preserves placeholders (%@, %.0f, etc.)
        • Translation caching for efficiency
        • Dry run mode to preview changes
        • AI-powered translation improvement suggestions

        EXAMPLES:
        # Translate entire file
        xcstrings-localizer Localizable.xcstrings

        # Translate specific keys
        xcstrings-localizer Localizable.xcstrings --keys "Welcome" --keys "Goodbye"

        # Force re-translation
        xcstrings-localizer Localizable.xcstrings --force

        # Preview changes without saving
        xcstrings-localizer Localizable.xcstrings --dry-run

        # Get AI suggestions for improving existing translations
        xcstrings-localizer Localizable.xcstrings --suggest

        SETUP:
        Set your OpenAI API key via:
        1. .env file: echo "OPENAI_API_KEY='sk-...'" > .env
        2. Environment: export OPENAI_API_KEY='sk-...'
        3. Command line: --api-key 'sk-...'
        """,
        version: "0.2.0"
    )

    @Argument(
        help: "Path to the .xcstrings file to localize",
        completion: .file(extensions: ["xcstrings"])
    )
    var inputFile: String

    @Option(
        name: [.short, .long],
        help: "Output file path (defaults to input file)"
    )
    var output: String?

    @Option(
        name: [.short, .long],
        help: "Specific keys to translate (can be specified multiple times)"
    )
    var keys: [String] = []

    @Option(
        name: [.short, .long],
        help: "Specific languages to process (can be specified multiple times, e.g., fr, de, es)"
    )
    var language: [String] = []

    @Flag(
        name: [.short, .long],
        help: "Force re-translation of already translated strings"
    )
    var force: Bool = false

    @Flag(
        name: [.short, .long],
        help: "Preview what would be translated without making changes"
    )
    var dryRun: Bool = false

    @Flag(
        name: [.short, .long],
        help: "Analyze existing translations and suggest improvements (interactive)"
    )
    var suggest: Bool = false

    @Option(
        name: [.short, .long],
        help: "OpenAI model to use for translation"
    )
    var model: String = "gpt-4o-mini"

    @Option(
        name: .long,
        help: "OpenAI API key (or set OPENAI_API_KEY environment variable)"
    )
    var apiKey: String?

    mutating func run() async throws {
        // Check for API key
        guard let apiKey = Config.loadAPIKey(from: apiKey) else {
            print("Error: OPENAI_API_KEY not found", to: &stderrStream)
            print("", to: &stderrStream)
            print("Set it using one of these methods:", to: &stderrStream)
            print("1. Create a .env file: echo \"OPENAI_API_KEY='your-key'\" > .env", to: &stderrStream)
            print("2. Environment variable: export OPENAI_API_KEY='your-key'", to: &stderrStream)
            print("3. Command line flag: --api-key 'your-key'", to: &stderrStream)
            print("", to: &stderrStream)
            print("Get your API key from: https://platform.openai.com/api-keys", to: &stderrStream)
            throw ExitCode.failure
        }

        // Load app description (optional)
        let appDescription = Config.loadAppDescription()
        if let desc = appDescription {
            print("Using app context: \(desc.prefix(60))...", to: &stderrStream)
        }

        // Validate input file
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: inputFile) {
            print("Error: File not found: \(inputFile)", to: &stderrStream)
            throw ExitCode.failure
        }

        if !inputFile.hasSuffix(".xcstrings") {
            print("Warning: Input file doesn't have .xcstrings extension", to: &stderrStream)
        }

        // Create localizer and run
        let localizer = XCStringsLocalizer(apiKey: apiKey, model: model, appDescription: appDescription)

        do {
            if suggest {
                // Run suggestion mode
                try await localizer.suggestImprovements(
                    inputPath: inputFile,
                    outputPath: output,
                    keys: keys.isEmpty ? nil : keys,
                    languages: language.isEmpty ? nil : language
                )
            } else {
                // Run normal translation mode
                let stats = try await localizer.localize(
                    inputPath: inputFile,
                    outputPath: output,
                    keys: keys.isEmpty ? nil : keys,
                    force: force,
                    dryRun: dryRun
                )

                print("\n✓ Localization complete!", to: &stderrStream)

                // Exit with non-zero if there were errors
                if stats.errors > 0 {
                    throw ExitCode(1)
                }
            }
        } catch let error as DecodingError {
            print("Error: Invalid JSON in file", to: &stderrStream)
            print(error.localizedDescription, to: &stderrStream)
            throw ExitCode.failure
        } catch {
            print("Error: \(error.localizedDescription)", to: &stderrStream)
            throw ExitCode.failure
        }
    }
}
