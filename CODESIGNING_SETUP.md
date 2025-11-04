# Code Signing and Notarization Setup

This guide will help you set up code signing and notarization for automated releases in GitHub Actions.

## Prerequisites

- Apple Developer account ($99/year)
- Xcode installed on your Mac
- Access to your GitHub repository settings

## Step 1: Create a Developer ID Application Certificate

1. Open **Keychain Access** on your Mac
2. Go to **Keychain Access** → **Certificate Assistant** → **Request a Certificate from a Certificate Authority**
3. Enter your email address and name
4. Select **Saved to disk** and click **Continue**
5. Save the certificate request file

6. Go to [Apple Developer Certificates](https://developer.apple.com/account/resources/certificates/list)
7. Click **+** to create a new certificate
8. Select **Developer ID Application** and click **Continue**
9. Upload the certificate request file you created
10. Download the certificate (`.cer` file)

11. Double-click the downloaded certificate to install it in Keychain Access
12. In Keychain Access, find your certificate under **My Certificates**
   - It should be named something like "Developer ID Application: Your Name (TEAM_ID)"

## Step 2: Export Certificate as .p12

1. In Keychain Access, select your **Developer ID Application** certificate
2. Right-click and select **Export "Developer ID Application: ..."**
3. Choose a location and save as `.p12` format
4. **Set a password** when prompted (you'll need this later)
5. Enter your Mac password to allow the export

## Step 3: Get Your Team ID

1. Go to [Apple Developer Account Membership](https://developer.apple.com/account#MembershipDetailsCard)
2. Find your **Team ID** (it's a 10-character alphanumeric code)

## Step 4: Create App-Specific Password

1. Go to [Apple ID Account](https://appleid.apple.com/account/manage)
2. Sign in with your Apple ID (the one you use for Developer account)
3. In the **Security** section, under **App-Specific Passwords**, click **Generate Password**
4. Enter a label like "GitHub Actions Notarization"
5. Copy the generated password (you won't be able to see it again)

## Step 5: Prepare Secrets for GitHub

### Convert Certificate to Base64

Open Terminal and run:

```bash
base64 -i /path/to/your/certificate.p12 | pbcopy
```

This copies the base64-encoded certificate to your clipboard.

### Get Your Signing Identity

In Terminal, run:

```bash
security find-identity -v -p codesigning
```

Look for the line with "Developer ID Application" and copy the **full name** in quotes, e.g.:
```
"Developer ID Application: Your Name (TEAM_ID)"
```

## Step 6: Add Secrets to GitHub

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** for each of the following:

### Required Secrets:

| Secret Name | Description | Example/Notes |
|-------------|-------------|---------------|
| `APPLE_CERTIFICATE_BASE64` | Base64-encoded .p12 certificate | (long string from Step 5) |
| `APPLE_CERTIFICATE_PASSWORD` | Password for .p12 file | The password you set in Step 2 |
| `KEYCHAIN_PASSWORD` | Temporary keychain password | Any random password (e.g., `temp-keychain-pass-123`) |
| `APPLE_SIGNING_IDENTITY` | Full certificate name | `"Developer ID Application: Your Name (TEAM_ID)"` |
| `APPLE_ID` | Your Apple ID email | `your-email@example.com` |
| `APPLE_TEAM_ID` | Your Team ID | `ABC1234567` |
| `APPLE_APP_PASSWORD` | App-specific password | (from Step 4) |

## Step 7: Test the Setup

Once all secrets are added, commit and push any change to trigger the workflow:

```bash
git commit --allow-empty -m "test: trigger release workflow"
git push
```

Check the Actions tab in GitHub to monitor the workflow. If successful, your binary will be:
- Code signed with your Developer ID
- Notarized by Apple
- Safe to distribute without Gatekeeper warnings

## Troubleshooting

### "Developer ID Application" not found
- Make sure you downloaded and installed the certificate from Apple Developer
- Verify it's in your **login** keychain in Keychain Access

### Notarization fails
- Verify your Apple ID is enrolled in the Apple Developer Program
- Check that your app-specific password is correct
- Make sure your Team ID matches your Developer account

### "security: SecKeychainItemImport: MAC verification failed"
- The certificate password is incorrect
- Re-export the .p12 with a new password and update the secret

## Security Notes

- Never commit certificates or passwords to your repository
- GitHub Secrets are encrypted and only exposed to Actions
- The temporary keychain is created and destroyed during each workflow run
- Consider rotating your app-specific password periodically

## Additional Resources

- [Apple Developer Documentation](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [notarytool Documentation](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow)
