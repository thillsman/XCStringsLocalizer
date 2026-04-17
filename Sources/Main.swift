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
        • Self-update capability

        EXAMPLES:
        # Auto-discover and translate all .xcstrings files in current directory
        xcstrings-localizer

        # Translate a specific file
        xcstrings-localizer Localizable.xcstrings

        # Translate multiple files
        xcstrings-localizer Localizable.xcstrings InfoPlist.xcstrings

        # Translate specific keys
        xcstrings-localizer Localizable.xcstrings --keys "Welcome" --keys "Goodbye"

        # Force re-translation
        xcstrings-localizer --force

        # Preview changes without saving
        xcstrings-localizer --dry-run

        # Get AI suggestions for improving existing translations
        xcstrings-localizer --suggest

        # Update to latest version
        xcstrings-localizer update

        SETUP:
        Set your OpenAI API key via:
        1. .env file: echo "OPENAI_API_KEY='sk-...'" > .env
        2. Environment: export OPENAI_API_KEY='sk-...'
        3. Command line: --api-key 'sk-...'
        """,
        version: UpdateChecker.currentVersion,
        subcommands: [Localize.self, Update.self],
        defaultSubcommand: Localize.self
    )
}

// MARK: - Localize Subcommand

struct Localize: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "localize",
        abstract: "Translate .xcstrings files (default command)"
    )

    @Argument(
        help: "Path(s) to .xcstrings file(s) to localize (if not specified, finds all .xcstrings files in current directory)",
        completion: .file(extensions: ["xcstrings"])
    )
    var inputFiles: [String] = []

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
    var model: String = Constants.defaultModel

    @Option(
        name: .long,
        help: "OpenAI API key (or set OPENAI_API_KEY environment variable)"
    )
    var apiKey: String?

    mutating func run() async throws {
        // Check for updates in background (non-blocking)
        UpdateChecker.checkForUpdatesAsync()

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

        // Determine which files to process
        let filesToProcess: [String]
        if inputFiles.isEmpty {
            // Auto-discover .xcstrings files
            let discovered = XcodeProjectParser.findXCStringsFiles()
            if discovered.isEmpty {
                print("Error: No .xcstrings files found in current directory or subdirectories", to: &stderrStream)
                throw ExitCode.failure
            }
            print("Found \(discovered.count) .xcstrings file(s):", to: &stderrStream)
            for file in discovered {
                print("  • \(file)", to: &stderrStream)
            }
            print("", to: &stderrStream)
            filesToProcess = discovered
        } else {
            // Validate provided files
            let fileManager = FileManager.default
            for file in inputFiles {
                if !fileManager.fileExists(atPath: file) {
                    print("Error: File not found: \(file)", to: &stderrStream)
                    throw ExitCode.failure
                }
                if !file.hasSuffix(".xcstrings") {
                    print("Warning: \(file) doesn't have .xcstrings extension", to: &stderrStream)
                }
            }
            filesToProcess = inputFiles
        }

        // Create localizer
        let localizer = XCStringsLocalizer(apiKey: apiKey, model: model, appDescription: appDescription)

        // Process each file
        var totalErrors = 0
        for (index, inputFile) in filesToProcess.enumerated() {
            if filesToProcess.count > 1 {
                print("", to: &stderrStream)
                print("═══════════════════════════════════════════════════════════", to: &stderrStream)
                print("Processing file \(index + 1)/\(filesToProcess.count)", to: &stderrStream)
                print("═══════════════════════════════════════════════════════════", to: &stderrStream)
            }

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
                        languages: language.isEmpty ? nil : language,
                        force: force,
                        dryRun: dryRun
                    )

                    totalErrors += stats.errors
                }
            } catch let error as DecodingError {
                print("Error: Invalid JSON in file \(inputFile)", to: &stderrStream)
                print(error.localizedDescription, to: &stderrStream)
                totalErrors += 1
            } catch {
                print("Error processing \(inputFile): \(error.localizedDescription)", to: &stderrStream)
                totalErrors += 1
            }
        }

        if filesToProcess.count > 1 {
            print("", to: &stderrStream)
            print("═══════════════════════════════════════════════════════════", to: &stderrStream)
            print("All .xcstrings files processed!", to: &stderrStream)
            print("═══════════════════════════════════════════════════════════", to: &stderrStream)
        }

        // Process localized-extras if the directory exists
        if let extrasDir = XcodeProjectParser.findLocalizedExtrasDirectory(),
           !suggest {  // Don't process extras in suggestion mode
            print("", to: &stderrStream)
            print("Found localized-extras directory", to: &stderrStream)

            let sourceFiles = XcodeProjectParser.findLocalizedExtrasSourceFiles(in: extrasDir)
            if !sourceFiles.isEmpty {
                print("Found \(sourceFiles.count) source file(s) to translate:", to: &stderrStream)
                for file in sourceFiles {
                    let filename = (file as NSString).lastPathComponent
                    print("  • \(filename)", to: &stderrStream)
                }
                print("", to: &stderrStream)

                // Get target languages (same as for xcstrings)
                // We'll use the localizer's client directly
                let client = OpenAIClient(apiKey: apiKey, model: model, appDescription: appDescription)

                // Determine target languages
                var targetLanguages: Set<String> = []
                if let projectLanguages = XcodeProjectParser.getProjectLanguages() {
                    targetLanguages = Set(projectLanguages)
                } else if !filesToProcess.isEmpty {
                    // Get languages from first xcstrings file
                    if let data = try? Data(contentsOf: URL(fileURLWithPath: filesToProcess[0])),
                       let xcstrings = try? JSONDecoder().decode(XCStringsFile.self, from: data) {
                        for entry in xcstrings.strings.values {
                            if let localizations = entry.localizations {
                                targetLanguages.formUnion(localizations.keys)
                            }
                        }
                        targetLanguages.remove(xcstrings.sourceLanguage)
                    }
                }

                if targetLanguages.isEmpty {
                    print("Warning: No target languages found for localized-extras", to: &stderrStream)
                } else {
                    print("Translating to: \(targetLanguages.sorted().joined(separator: ", "))", to: &stderrStream)
                    print("", to: &stderrStream)

                    for sourceFile in sourceFiles {
                        let filename = (sourceFile as NSString).lastPathComponent
                        print("Processing: \(filename)", to: &stderrStream)

                        // Read source file
                        guard let content = try? String(contentsOfFile: sourceFile, encoding: .utf8) else {
                            print("  ✗ Error reading file", to: &stderrStream)
                            totalErrors += 1
                            continue
                        }

                        for targetLang in targetLanguages.sorted() {
                            let targetPath = XcodeProjectParser.localizedFilePath(for: sourceFile, language: targetLang)
                            let targetFilename = (targetPath as NSString).lastPathComponent

                            // Skip if target already exists (unless force)
                            if FileManager.default.fileExists(atPath: targetPath) && !force {
                                print("  ⊙ \(targetFilename) (already exists, skipping)", to: &stderrStream)
                                continue
                            }

                            if !dryRun {
                                do {
                                    let translated = try await client.translateFile(
                                        content: content,
                                        targetLanguage: targetLang,
                                        filename: filename
                                    )

                                    try translated.write(toFile: targetPath, atomically: true, encoding: .utf8)
                                    print("  ✓ \(targetFilename)", to: &stderrStream)
                                } catch {
                                    print("  ✗ \(targetFilename): \(error.localizedDescription)", to: &stderrStream)
                                    totalErrors += 1
                                }
                            } else {
                                print("  ○ \(targetFilename) (would translate)", to: &stderrStream)
                            }
                        }
                    }
                }
            }
        }

        print("\n✓ Localization complete!", to: &stderrStream)

        // Exit with non-zero if there were errors
        if totalErrors > 0 {
            throw ExitCode(1)
        }
    }
}

// MARK: - Update Subcommand

struct Update: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update xcstrings-localizer to the latest version"
    )

    mutating func run() async throws {
        try await UpdateChecker.performUpdate()
    }
}
