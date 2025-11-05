# XCStrings Localizer (Swift)

A native Swift command-line tool for automatically localizing Xcode `.xcstrings` files using AI-powered translation via OpenAI's API.

## Features

- ✅ **Automatic Translation**: Translates strings to all target languages in your `.xcstrings` file
- ✅ **AI-Powered Suggestions**: Interactive review of existing translations with improvement suggestions
- ✅ **Batch Processing**: Groups strings for efficient API calls (15 strings at a time)
- ✅ **App Context Support**: Optional app description for better translation quality
- ✅ **Context-Aware**: Uses comments for better translation accuracy
- ✅ **Smart Skipping**: Respects `shouldTranslate: false` and skips already translated strings
- ✅ **Selective Translation**: Translate specific keys or the entire file
- ✅ **Preview Mode**: Dry-run to see changes before applying
- ✅ **Placeholder Preservation**: Maintains format specifiers (`%@`, `%.0f`, etc.)
- ✅ **Translation Caching**: Avoids redundant API calls
- ✅ **Zero Dependencies**: Pure Swift, no external packages except ArgumentParser

## Installation

### Option 1: Build from Source (Recommended)

```bash
cd XCStringsLocalizer
swift build -c release
```

The binary will be at `.build/release/xcstrings-localizer`

### Option 2: Install to /usr/local/bin

```bash
cd XCStringsLocalizer
swift build -c release
sudo cp .build/release/xcstrings-localizer /usr/local/bin/
```

Now you can use `xcstrings-localizer` from anywhere!

### Option 3: Use Swift Package Manager

```bash
cd XCStringsLocalizer
swift run xcstrings-localizer --help
```

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
# Translate entire file
xcstrings-localizer Localizable.xcstrings

# Or if not installed globally
swift run xcstrings-localizer Localizable.xcstrings
```

### Common Options

```bash
# Preview changes (dry run)
xcstrings-localizer Localizable.xcstrings --dry-run

# Translate specific keys
xcstrings-localizer Localizable.xcstrings --keys "Welcome" --keys "Goodbye"

# Force re-translation
xcstrings-localizer Localizable.xcstrings --force

# Get AI suggestions for improving existing translations (interactive)
xcstrings-localizer Localizable.xcstrings --suggest

# Analyze only French translations
xcstrings-localizer Localizable.xcstrings --suggest --language fr

# Analyze French and German translations
xcstrings-localizer Localizable.xcstrings --suggest --language fr --language de

# Analyze specific keys for improvement suggestions
xcstrings-localizer Localizable.xcstrings --suggest --keys "Welcome"

# Analyze specific keys in French only
xcstrings-localizer Localizable.xcstrings --suggest --keys "Welcome" --language fr

# Specify output file
xcstrings-localizer input.xcstrings --output output.xcstrings

# Use different model
xcstrings-localizer Localizable.xcstrings --model gpt-4o
```

### Get Help

```bash
xcstrings-localizer --help
```

## Examples

### Example 1: First-Time Translation

```bash
# Preview what will be translated
xcstrings-localizer ~/MyApp/Localizable.xcstrings --dry-run

# Perform the translation
xcstrings-localizer ~/MyApp/Localizable.xcstrings
```

**Output:**
```
Loading: /Users/you/MyApp/Localizable.xcstrings
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

### Example 2: Update Marketing Copy

```bash
xcstrings-localizer Localizable.xcstrings \
  --keys "App Store Description" \
  --keys "Premium Feature Title" \
  --force \
  --model gpt-4o
```

### Example 3: Review and Improve Existing Translations

```bash
xcstrings-localizer Localizable.xcstrings --suggest
```

**Interactive Output:**
```
Loading: Localizable.xcstrings
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

XCSTRINGS="${SRCROOT}/Localizable.xcstrings"

# Check for untranslated strings
if /usr/local/bin/xcstrings-localizer "$XCSTRINGS" --dry-run 2>&1 | grep -q "Translations created"; then
    echo "warning: Untranslated strings detected. Run: xcstrings-localizer $XCSTRINGS"
fi
```

### Example 5: Pre-Commit Hook

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash

# Find modified .xcstrings files
CHANGED=$(git diff --cached --name-only --diff-filter=ACM | grep '\.xcstrings$')

if [ ! -z "$CHANGED" ]; then
    for file in $CHANGED; do
        echo "Auto-translating: $file"
        xcstrings-localizer "$file"
        git add "$file"
    done
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
| `--model` | `-m` | OpenAI model to use | `gpt-4o-mini` |
| `--api-key` | | API key (overrides env var) | From env |
| `--help` | `-h` | Show help | |
| `--version` | | Show version | |

## Models

Available OpenAI models:

- **gpt-4o-mini** (default): Fast and cost-effective (~$0.15 per 1M tokens)
- **gpt-4o**: Most capable, higher quality (~$2.50 per 1M tokens)
- **gpt-4-turbo**: Balanced option

## Translation Behavior

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
├── Package.swift              # Swift Package manifest
├── Sources/
│   ├── Main.swift            # CLI entry point
│   ├── XCStringsModels.swift # Data models
│   ├── OpenAIClient.swift    # API client
│   ├── Localizer.swift       # Core logic
│   └── Config.swift          # Configuration
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

      - name: Translate strings
        env:
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
        run: |
          find . -name "*.xcstrings" | while read file; do
            XCStringsLocalizer/.build/release/xcstrings-localizer "$file"
          done

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

### Cost Estimates

For a typical app with 1000 strings and 10 target languages:

- **gpt-4o-mini**: ~$0.50-$1.00 for complete translation (with batching)
- **gpt-4o**: ~$10-$20 for complete translation (with batching)

**Without batching, costs would be ~10-15x higher!**

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
