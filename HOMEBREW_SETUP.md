# Homebrew Distribution Setup Guide

This guide explains how to distribute XCStrings Localizer via Homebrew.

## Setup Steps

### 1. Create a Homebrew Tap Repository

Create a new GitHub repository named `homebrew-xcstrings`:
- Repository URL: `https://github.com/thillsman/homebrew-xcstrings`
- Description: "Homebrew tap for XCStrings Localizer"
- Public repository

### 2. Add the Formula

Copy the `xcstrings-localizer.rb` file to your tap repository:

```bash
# Clone your new tap repository
git clone https://github.com/thillsman/homebrew-xcstrings.git
cd homebrew-xcstrings

# Create Formula directory
mkdir -p Formula

# Copy the formula file
cp /path/to/XCStringsLocalizer/xcstrings-localizer.rb Formula/

# Commit and push
git add Formula/xcstrings-localizer.rb
git commit -m "Add xcstrings-localizer formula"
git push
```

### 3. Users Can Install Via Homebrew

Once your tap is set up, users can install with:

```bash
# Add your tap
brew tap thillsman/xcstrings

# Install the tool
brew install xcstrings-localizer
```

Or in one command:

```bash
brew install thillsman/xcstrings/xcstrings-localizer
```

## Updating the Formula for New Releases

When you release a new version:

1. **Update the version in the formula**:
   - Change the `url` to point to the new tag
   - Update the `sha256` hash
   - Update the version in the `test` block

2. **Calculate the new SHA256**:
   ```bash
   curl -sL https://github.com/thillsman/XCStringsLocalizer/archive/refs/tags/vX.X.X.tar.gz | shasum -a 256
   ```

3. **Test the formula locally**:
   ```bash
   brew install --build-from-source Formula/xcstrings-localizer.rb
   brew test xcstrings-localizer
   brew uninstall xcstrings-localizer
   ```

4. **Commit and push** the updated formula

## Automation (Optional)

You can automate formula updates using GitHub Actions:

1. Add a workflow to your tap repository that watches for new releases
2. Automatically calculate SHA256 and update the formula
3. Create a PR for review

## Alternative: Submit to Homebrew Core

For wider distribution, you could submit to Homebrew's main repository, but this requires:
- The tool to be notable/popular
- Meeting Homebrew's strict guidelines
- Community review process

Your own tap is recommended for now and gives you full control.

## Testing Locally

Before pushing to your tap, test the formula locally:

```bash
# Install from local file
brew install --build-from-source xcstrings-localizer.rb

# Test it works
xcstrings-localizer --version

# Run the formula's test
brew test xcstrings-localizer

# Uninstall when done testing
brew uninstall xcstrings-localizer
```

## Current Formula

The formula is set up to:
- Build from source using Swift
- Requires Xcode 14.0 or later
- Only works on macOS
- Installs the binary to Homebrew's bin directory
- Includes a version test

Formula location: `xcstrings-localizer.rb`
