# XCStrings Localizer (Swift)

A native Swift command-line tool for automatically localizing Xcode `.xcstrings` files using AI-powered translation via OpenAI's API.

## Features

- ✅ **Auto-Discovery**: Automatically finds all `.xcstrings` files in your project
- ✅ **Xcode Project Integration**: Reads target languages from your project's `knownRegions`
- ✅ **Multi-File Support**: Process one, multiple, or all `.xcstrings` files at once
- ✅ **Localized Extras**: Automatically translates markdown/text files in `localized-extras/` directory
- ✅ **Automatic Translation**: Translates strings to all target languages
- ✅ **AI-Powered Suggestions**: Interactive review of existing translations with improvement suggestions
- ✅ **Batch Processing**: Groups strings for efficient API calls (15 strings at a time)
- ✅ **App Context Support**: Optional app description for better translation quality
- ✅ **Context-Aware**: Uses comments for better translation accuracy
- ✅ **Smart Skipping**: Respects `shouldTranslate: false` and skips already translated strings
- ✅ **Selective Translation**: Translate specific keys or the entire file
- ✅ **Preview Mode**: Dry-run to see changes before applying
- ✅ **Placeholder Preservation**: Maintains format specifiers (`%@`, `%.0f`, etc.)
- ✅ **Translation Caching**: Avoids redundant API calls
- ✅ **Self-Updating**: Built-in update command and version notifications
- ✅ **Zero Dependencies**: Pure Swift, no external packages except ArgumentParser

## Installation

### Homebrew (Recommended)

```bash
brew install thillsman/xcstrings/xcstrings-localizer
```

Or tap first, then install:

```bash
brew tap thillsman/xcstrings
brew install xcstrings-localizer
```

### Quick Install Script

One command to download and install the latest version:

```bash
curl -fsSL https://raw.githubusercontent.com/thillsman/XCStringsLocalizer/main/install.sh | bash
```

This will:
- Download the latest release from GitHub
- Install to `/usr/local/bin`
- Make it available globally as `xcstrings-localizer`

### Alternative Installation Methods

<details>
<summary>Build from Source</summary>

```bash
git clone https://github.com/thillsman/XCStringsLocalizer.git
cd XCStringsLocalizer
swift build -c release
sudo cp .build/release/xcstrings-localizer /usr/local/bin/
```
</details>

<details>
<summary>Use Swift Package Manager (Development)</summary>

```bash
git clone https://github.com/thillsman/XCStringsLocalizer.git
cd XCStringsLocalizer
swift run xcstrings-localizer --help
```
</details>

### Updating

**If installed via Homebrew:**
```bash
brew upgrade xcstrings-localizer
```

**If installed via script or built from source:**
```bash
xcstrings-localizer update
```

Or re-run the installation script:
```bash
curl -fsSL https://raw.githubusercontent.com/thillsman/XCStringsLocalizer/main/install.sh | bash
```

The tool will also notify you when new versions are available.

## Setup

### Set Your OpenAI API Key

You have three options:

**Option 1: .env file (Recommended)**

```bash
cd XCStringsLocalizer
echo "OPENAI_API_KEY='your-api-key-here'" > .env
```

**Option 2: Environment variable**

```bash
export OPENAI_API_KEY='your-api-key-here'
```

**Option 3: Command line flag**

```bash
xcstrings-localizer input.xcstrings --api-key 'your-api-key-here'
```

Get your API key from: https://platform.openai.com/api-keys

### (Optional) Add App Description for Better Translations

Adding context about your app significantly improves translation quality. Add this to your `.env` file:

```bash
APP_DESCRIPTION='These are user-facing strings for an app called Sticky Widgets. The app allows users to create new notes, customize their appearance, and place them as widgets on the user'\''s iOS home screen.'
```

**Why this helps:**
- ✅ LLM understands the domain (e.g., "note" means a written note, not a musical note)
- ✅ Maintains consistent terminology across translations
- ✅ Better context for ambiguous words
- ✅ More natural translations that fit your app's tone

**Example `.env` file:**
```bash
OPENAI_API_KEY='sk-proj-...'
APP_DESCRIPTION='A productivity app for managing daily tasks and reminders on iOS'
```

## Usage

### Basic Usage

```bash
# Auto-discover and translate all .xcstrings files in your project
xcstrings-localizer

# Translate a specific file
xcstrings-localizer Localizable.xcstrings

# Translate multiple specific files
xcstrings-localizer Localizable.xcstrings InfoPlist.xcstrings

# Or if not installed globally
swift run xcstrings-localizer
```

### How It Works

1. **Language Detection**: Checks your Xcode project's `knownRegions` first, then falls back to languages in the catalog
2. **File Discovery**: If no files specified, automatically finds all `.xcstrings` files in current directory and subdirectories
3. **Smart Translation**: Only translates missing or new strings (use `--force` to retranslate all)
4. **Localized Extras**: Automatically translates files in `localized-extras/` directory (see below)

### Common Options

```bash
# Auto-discover and preview changes (dry run)
xcstrings-localizer --dry-run

# Auto-discover and force re-translation of all strings
xcstrings-localizer --force

# Translate specific keys in discovered files
xcstrings-localizer --keys "Welcome" --keys "Goodbye"

# Translate a specific file with preview
xcstrings-localizer Localizable.xcstrings --dry-run

# Get AI suggestions for improving existing translations (interactive)
xcstrings-localizer --suggest

# Analyze only French translations
xcstrings-localizer --suggest --language fr

# Analyze French and German translations in a specific file
xcstrings-localizer Localizable.xcstrings --suggest --language fr --language de

# Analyze specific keys for improvement suggestions
xcstrings-localizer --suggest --keys "Welcome"

# Specify output file (only works with single input file)
xcstrings-localizer Localizable.xcstrings --output output.xcstrings

# Use different model
xcstrings-localizer --model gpt-5
```

### Get Help

```bash
xcstrings-localizer --help
```

## Localized Extras

The tool automatically translates additional files beyond `.xcstrings` catalogs!

### Setup

Create a `localized-extras/` directory in your project root and place any files you want translated:

```bash
mkdir localized-extras
cp appstore-description.md localized-extras/
cp release-notes.txt localized-extras/
```

### How It Works

1. Place source files (without language suffixes) in `localized-extras/`
2. Run the localizer as normal
3. Translated versions are automatically created with language suffixes

**Example:**
```
localized-extras/
├── appstore.md              # Source file
├── appstore.fr.md           # Auto-generated French
├── appstore.de.md           # Auto-generated German
├── appstore.ja.md           # Auto-generated Japanese
└── release-notes.txt        # Source file
    ├── release-notes.fr.txt # Auto-generated
    └── ...
```

### Supported File Types

Any text file format:
- Markdown (`.md`)
- Plain text (`.txt`)
- HTML (`.html`)
- JSON (`.json`)
- And more!

### Behavior

- **Smart Detection**: Files with language suffixes (`.fr.md`, `.de.txt`) are ignored as source files
- **Skip Existing**: Already-translated files are skipped (use `--force` to retranslate)
- **Same Languages**: Uses the same target languages as your `.xcstrings` files
- **Preserves Formatting**: Maintains markdown syntax, code blocks, and special characters
- **Dry Run Support**: Preview with `--dry-run` before translating

### Use Cases

Perfect for translating:
- 📱 App Store descriptions
- 📝 Release notes
- 📄 README files
- 🔒 Privacy policies
- 📋 Terms of service
- 📚 Documentation

## Examples

### Example 1: Auto-Discovery in Your Project

```bash
# Navigate to your Xcode project directory
cd ~/MyApp

# Preview what will be translated
xcstrings-localizer --dry-run

# Perform the translation
xcstrings-localizer
```

**Output:**
```
Found 1 .xcstrings file(s):
  • /Users/you/MyApp/Localizable.xcstrings

Loading: /Users/you/MyApp/Localizable.xcstrings
Found Xcode project with knownRegions: ar, de, es, fr, hi, it, ja, ko, pt, ru
Using app context: A productivity app for managing daily tasks and reminders...
Source language: en
Target languages: ar, de, es, fr, hi, it, ja, ko, pt, ru
Total keys in file: 247

Translating...

Translating 45 strings to fr...
  Batch 1/3 (15 strings)
  Batch 2/3 (15 strings)
  Batch 3/3 (15 strings)
Translating 45 strings to de...
  Batch 1/3 (15 strings)
  Batch 2/3 (15 strings)
  Batch 3/3 (15 strings)
...

Saving to: /Users/you/MyApp/Localizable.xcstrings

┌─────────────────────────────────────┬────────┐
│ Translation Summary                 │        │
├─────────────────────────────────────┼────────┤
│ Total keys                          │    247 │
│ Translations created                │    450 │
│ Skipped (shouldTranslate=false)     │     20 │
│ Skipped (already translated)        │   2250 │
│ Errors                              │      0 │
└─────────────────────────────────────┴────────┘

✓ Localization complete!
```

### Example 2: Translate App Store Materials

```bash
# Create localized-extras directory with marketing materials
mkdir localized-extras
cp marketing/appstore-description.md localized-extras/
cp marketing/release-notes.md localized-extras/

# Run localizer - translates both .xcstrings and extras
xcstrings-localizer
```

**Output:**
```
Found 1 .xcstrings file(s):
  • Localizable.xcstrings

... (xcstrings translation) ...

Found localized-extras directory
Found 2 source file(s) to translate:
  • appstore-description.md
  • release-notes.md

Translating to: fr, de, es, ja

Processing: appstore-description.md
  ✓ appstore-description.fr.md
  ✓ appstore-description.de.md
  ✓ appstore-description.es.md
  ✓ appstore-description.ja.md

Processing: release-notes.md
  ✓ release-notes.fr.md
  ✓ release-notes.de.md
  ✓ release-notes.es.md
  ✓ release-notes.ja.md
```

### Example 3: Review and Improve Existing Translations

```bash
# Auto-discover and suggest improvements
xcstrings-localizer --suggest

# Or for a specific file
xcstrings-localizer Localizable.xcstrings --suggest
```

**Interactive Output:**
```
Found 1 .xcstrings file(s):
  • /Users/you/MyApp/Localizable.xcstrings

Loading: Localizable.xcstrings
Found Xcode project with knownRegions: de, es, fr, ja
Source language: en
Target languages: de, es, fr, ja

Analyzing translations...

Analyzing 247 translations in de...
  Batch 1/17 (15 strings)
  Batch 2/17 (15 strings)
  ...
    Found 3 high-confidence suggestion(s)

┌────────────────────────────────────────────────────────────┐
│ Found 8 suggestion(s) for improvement
└────────────────────────────────────────────────────────────┘

[1/8] Key: welcome_message
Language: French (Confidence: 5/5)

Current:   Bienvenue à notre application
Suggested: Bienvenue dans notre application

Reason: More natural and idiomatic French expression. "dans" is more commonly used with applications than "à".

Accept this suggestion? [y/N/q] y
✓ Applied

[2/8] Key: settings_title
Language: German (Confidence: 4/5)

Current:   Einstellungen Seite
Suggested: Einstellungen

Reason: More concise and natural. "Seite" (page) is redundant in this UI context.

Accept this suggestion? [y/N/q] n
✗ Skipped

...

Saving changes to: Localizable.xcstrings

✓ Successfully applied 5 suggestion(s)!
Rejected 3 suggestion(s).
```

**Features:**
- 🤖 AI analyzes existing translations for quality
- 🎯 Only suggests improvements with high confidence (4-5 out of 5)
- 📊 Shows reasoning for each suggestion
- ✋ Interactive approval - you decide what to apply
- 🔍 Can filter by specific keys using `--keys`
- 🌍 Can filter by specific languages using `--language`
- 💾 Changes only saved when you accept suggestions

### Example 4: Xcode Build Phase Integration

Add a new "Run Script" phase in Xcode:

```bash
#!/bin/bash

cd "${SRCROOT}"

# Check for untranslated strings using auto-discovery
if /usr/local/bin/xcstrings-localizer --dry-run 2>&1 | grep -q "Translations created"; then
    echo "warning: Untranslated strings detected. Run: xcstrings-localizer"
fi
```

### Example 5: Pre-Commit Hook

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash

# Find modified .xcstrings files
CHANGED=$(git diff --cached --name-only --diff-filter=ACM | grep '\.xcstrings$')

if [ ! -z "$CHANGED" ]; then
    echo "Auto-translating modified .xcstrings files..."

    # Translate all modified files at once
    xcstrings-localizer $CHANGED

    # Re-add the translated files
    git add $CHANGED
fi
```

## Command Line Options

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--output` | `-o` | Output file path | Input file |
| `--keys` | `-k` | Translate specific keys (repeatable) | All keys |
| `--language` | `-l` | Specific languages to process (repeatable, e.g., fr, de) | All languages |
| `--force` | `-f` | Re-translate already translated strings | `false` |
| `--dry-run` | `-d` | Preview changes without saving | `false` |
| `--suggest` | `-s` | Analyze and suggest improvements (interactive) | `false` |
| `--model` | `-m` | OpenAI model to use | `gpt-5-mini` |
| `--api-key` | | API key (overrides env var) | From env |
| `--help` | `-h` | Show help | |
| `--version` | | Show version | |

## Models

Available OpenAI models (2025):

- **gpt-5-nano**: Lowest cost
  - Input: $0.05 per 1M tokens
  - Output: $0.40 per 1M tokens
  - 128K context
  
- **gpt-5-mini** (default): Best cost-performance balance for translation
  - Input: $0.25 per 1M tokens
  - Output: $2.00 per 1M tokens
  - 128K context

- **gpt-5**: Highest quality, recommended for premium content
  - Input: $1.25 per 1M tokens
  - Output: $10.00 per 1M tokens
  - 128K context

## Translation Behavior

### Language Detection

The tool determines target languages in this priority order:

1. **Xcode Project's `knownRegions`** (primary) - Searches up to 3 parent directories for `.xcodeproj` files
2. **Catalog Languages** (fallback) - Uses languages already defined in the `.xcstrings` file

This ensures translations match your Xcode project's supported languages.

### What Gets Translated

A string is translated if:
1. ✅ It doesn't have `shouldTranslate: false`
2. ✅ AND one of:
   - No localization exists for target language
   - Target language has `state: "new"`
   - Target language value is empty
   - `--force` flag is used

### Source Text Selection

Priority order:
1. English (`en`) localization value
2. The key itself if no English localization

### Placeholder Preservation

All format specifiers are preserved:
- `%@` - String
- `%d`, `%i` - Integer
- `%.0f`, `%.2f` - Float with precision
- `%1$@`, `%2$d` - Positional
- `\n` - Newlines

## Project Structure

```
XCStringsLocalizer/
├── Package.swift                # Swift Package manifest
├── Sources/
│   ├── Main.swift              # CLI entry point & argument parsing
│   ├── XCStringsModels.swift   # Data models for .xcstrings format
│   ├── OpenAIClient.swift      # OpenAI API client
│   ├── Localizer.swift         # Core translation logic
│   ├── XcodeProjectParser.swift # Xcode project & file discovery
│   └── Config.swift            # Configuration (.env loading)
└── README.md
```

## Development

### Build

```bash
swift build
```

### Run Tests

```bash
swift test
```

### Debug Build

```bash
swift build
.build/debug/xcstrings-localizer --help
```

### Release Build

```bash
swift build -c release
.build/release/xcstrings-localizer --help
```

## Integration with CI/CD

### GitHub Actions

```yaml
name: Auto-Translate Strings

on:
  push:
    paths:
      - '**.xcstrings'

jobs:
  translate:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3

      - name: Build localizer
        run: |
          cd XCStringsLocalizer
          swift build -c release

      - name: Translate strings (auto-discovery)
        env:
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
        run: |
          cd MyApp
          ../XCStringsLocalizer/.build/release/xcstrings-localizer

      - name: Commit changes
        run: |
          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
          git add *.xcstrings
          git diff --staged --quiet || git commit -m "chore: auto-translate strings"
          git push
```

### Fastlane

```ruby
lane :localize do
  sh "xcstrings-localizer ../MyApp/Localizable.xcstrings"
  build_app(scheme: "MyApp")
end
```

## Performance & Cost

### Batch Processing

The tool uses intelligent batch processing to minimize API calls:

- **Groups 15 strings per request** (configurable in source)
- **Reduces API calls by 93%** compared to single-string requests
- **Faster execution** due to fewer network round-trips
- **Lower costs** by reducing redundant prompt overhead

The tool also caches translations within a session to minimize costs on re-runs.

## Troubleshooting

### "OPENAI_API_KEY not found"

Set your API key:
```bash
echo "OPENAI_API_KEY='sk-...'" > .env
```

### Build Errors

Make sure you have Xcode command line tools:
```bash
xcode-select --install
```

### Permission Denied

Make the binary executable:
```bash
chmod +x .build/release/xcstrings-localizer
```

### Can't Find Binary

Either:
1. Use full path: `.build/release/xcstrings-localizer`
2. Install to PATH: `sudo cp .build/release/xcstrings-localizer /usr/local/bin/`

## Contributing

Contributions welcome! This is a pure Swift project with minimal dependencies.

## License

MIT License

## Credits

Built with:
- [Swift](https://swift.org/) - Apple's programming language
- [Swift Argument Parser](https://github.com/apple/swift-argument-parser) - CLI interface
- [OpenAI API](https://openai.com/) - AI translations

---

**Happy Localizing!** 🌍

## Author

[Tyler Hillsman](https://tylerhillsman.com)

[![Bluesky][bluesky_image]][bluesky_url]  
[![LinkedIn][linkedin_image]][linkedin_url]  
[![Mastodon][mastodon_image]][mastodon_url]

[bluesky_image]: https://img.shields.io/badge/Bluesky-0285FF?logo=bluesky&logoColor=fff
[bluesky_url]: https://bsky.app/profile/thillsman.me
[linkedin_image]: https://img.shields.io/badge/LinkedIn-0A66C2?logo=linkedin&logoColor=fff
[linkedin_url]: https://www.linkedin.com/in/tylerhillsman
[mastodon_image]: https://img.shields.io/mastodon/follow/412018?domain=https%3A%2F%2Fmastodon.social&style=social
[mastodon_url]: https://mastodon.social/@thillsman

## License & Attribution

XCStringsLocalizer is available under the **MIT License**. See `LICENSE` for details.