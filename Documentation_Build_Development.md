# BrightSide iOS - Build & Deployment Guide

This guide walks through building, versioning, and deploying the BrightSide iOS app.

## Quick Start

```bash
# Install dependencies
pod install

# Open workspace (not .xcodeproj!)
open Tinodios.xcworkspace

# Build for simulator
Cmd + B

# Archive for release
Product → Archive
```

## Environment Setup

### What You Need

- macOS 11.0+
- Xcode 13.0+
- CocoaPods
- Git
- Apple Developer account ($99/year)

### First Time Setup

Clone the repo and install dependencies:

```bash
git clone <repository-url>
cd qixsecure-bcp
git switch production
pod install
```

Always open `Tinodios.xcworkspace` after running `pod install`. Opening the `.xcodeproj` file will cause build errors.

### Dependencies

CocoaPods is used to manage third-party libraries. Here's what's included:

**Firebase**

- Firebase core, messaging, analytics, crashlytics
- Used for push notifications and crash tracking

**Media**

- MobileVLCKit 3.x - video playback
- WebRTC-lib 139.x - audio/video calls
- Kingfisher 5.x - image loading and caching

**Utilities**

- SQLite.swift - local database
- SwiftKeychainWrapper - secure storage
- PhoneNumberKit - phone number formatting

Update dependencies when needed:

```bash
# Update everything
pod update

# Update just one pod
pod update Firebase

# See what's outdated
pod outdated
```

The Podfile has a post-install hook that copies acknowledgements to the Settings bundle and cleans up some deployment target settings. You'll see this run automatically after `pod install`.

### Configuration Files

The project uses `.xcconfig` files to manage different environments:

**devel.xcconfig** - development/testing builds
**prod.xcconfig** - App Store releases

These files set things like:

- Server URLs (fochat.saleswarp.com)
- TLS/HTTPS settings
- App name and branding
- API keys

The build script reads version info from `prod.xcconfig`, which gets auto-updated from Git tags.

### Login Url for email and password login

Change the login url provided in LoginViewController.swift file

- Change the url ("https://bvfo-api.saleswarp.com") to new url

### Firebase Setup

Make sure `GoogleService-Info.plist` exists in the project root. You'll need to:

1. Add the plist file from Firebase Console
2. Configure push notification certs in Apple Developer Portal
3. Enable Cloud Messaging, Analytics, and Crashlytics in Firebase Console

## Building

### Pre-flight Checks

Before building, verify:

- [ ] Dependencies installed (`pod install`)
- [ ] Right config file (dev vs prod)
- [ ] Signing certs configured
- [ ] Version updated (if needed)
- [ ] Clean build folder (Cmd+Shift+K)

### Simulator Builds

From Xcode: Pick a simulator, hit Cmd+B to build, Cmd+R to run.

### Archives (App Store)

**In Xcode:**

1. Select "Any iOS Device" as the destination
2. Make sure you're using the Release configuration
3. Check signing settings - automatic signing is easier
4. Product → Archive
5. Wait a few minutes for it to build

The Organizer window will open when done. You'll see your archive with the app icon and version number. 6. Click on Distrubute app/use transporter application to distribute to play store.

### Common Build Problems

**"Can't find pod dependencies"**

```bash
pod deintegrate
pod install
```

**Code signing errors**

Check that you're logged into Xcode with your Apple ID (Preferences → Accounts), and that your provisioning profiles are up to date.

**Build script fails**

The versioning script needs execute permissions:

```bash
chmod +x Scripts/set_build_number.sh
```

## Apple Developer Account

### Signing

Use automatic signing unless you have a specific reason not to. It's much easier.

In Xcode:

1. Select target → Signing & Capabilities
2. Check "Automatically manage signing"
3. Select your team

Manual signing gives you more control but means managing provisioning profiles yourself.

## App Store Connect

### Creating the App

Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → My Apps → +

Fill in:

- Platform: iOS
- Name: BrightSide
- Language: English
- Bundle ID: (select from dropdown)
- SKU: something unique like BSIDE001

### App Information

Set your URLs:

- Privacy Policy: qixsecure.com/privacy
- Terms: qixsecure.com/terms

Pick a category (we're using Productivity).

### Pricing

Set whether the app is free or paid, which countries it's available in, and whether it releases automatically or manually after approval.

## Uploading Builds

### Using Xcode (Easiest)

After archiving:

1. Window → Organizer
2. Select your archive
3. Click "Distribute App"
4. Choose "App Store Connect"
5. Leave the checkboxes for uploading symbols and managing versions checked
6. Click Upload

### Using Transporter App

Download Transporter from the Mac App Store, sign in, drag your IPA file in, click Deliver.

## TestFlight

### Internal Testing

Internal testers (up to 100) get builds immediately:

1. App Store Connect → TestFlight
2. Pick your build
3. Add testers from your team
4. They'll get an email with a link

### External Testing

External testing (up to 10,000 testers) requires Beta App Review:

1. Pick a build for external testing
2. Fill in test details and feedback email
3. Submit for review
4. Add testers
5. Wait for approval (usually 24-48 hours)

## Submitting to App Store

### Prepare Assets

You'll need:

- Screenshots for different device sizes
- App description
- Keywords
- Support URL
- What's new text

Screenshot sizes:

- 6.5" (iPhone 14 Pro Max): 1290 x 2796
- 5.5" (iPhone 8 Plus): 1242 x 2208
- 12.9" iPad Pro: 2048 x 2732

### Submit

1. App Store Connect → Your App → Version
2. Click + next to Build and pick one
3. Fill in version info, what's new, keywords
4. Click "Submit for Review"

### Review Process

Reviews usually take 24-48 hours. You'll go through these statuses:

- Waiting for Review
- In Review
- Pending Developer Release (if you chose manual)
- Ready for Sale

Common rejection reasons:

- Missing info or broken links
- Crashes
- Privacy policy issues
- Not following Apple's guidelines

### Release

Choose automatic release (goes live right after approval) or manual release (you push the button when ready).

## Troubleshooting

**Invalid Binary**

Check that all capabilities are enabled and the provisioning profile is correct.

**Processing Stuck**

Give it 24 hours. Check [Apple System Status](https://developer.apple.com/system-status/) for any ongoing issues.

**Export Compliance**

You might need to answer questions about encryption. This can be automated by adding keys to Info.plist.

## Resources

- [Apple Developer Docs](https://developer.apple.com/documentation/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [TestFlight Guide](https://developer.apple.com/testflight/)
- [Xcode](https://developer.apple.com/xcode/)
- [CocoaPods](https://cocoapods.org/)
