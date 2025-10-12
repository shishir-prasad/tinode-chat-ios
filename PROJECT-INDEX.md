# QixSecure BCP - Project Index

**A comprehensive iOS messaging client built on the Tinode platform**

---

## 📋 Project Overview

| Property | Value |
|----------|-------|
| **Project Name** | QixSecure BCP |
| **Base Framework** | Tinodios (Tinode iOS Client) |
| **Platform** | iOS 14.0+ |
| **Language** | Swift |
| **Version** | 1.24.3 (Build 1830) |
| **Bundle ID** | co.tinode.tinodios |
| **License** | Apache 2.0 |
| **Status** | Beta - Usable and mostly stable |

## 🎯 Current Configuration

- **Server**: `fochat-dev.saleswarp.com`
- **Security**: TLS enabled (HTTPS/WSS)
- **API Key**: `AQAAAAABAAByCoXpLdVgii7-77YqZ6S4`
- **Environment**: Development/Production ready

---

## 🏗️ Project Architecture

### Core Components

#### 1. **TinodeSDK** - Core Messaging Framework
```
TinodeSDK/
├── Core Classes
│   ├── Tinode.swift          # Main SDK interface
│   ├── Connection.swift      # WebSocket connection management
│   ├── Topic.swift          # Base topic functionality
│   ├── ComTopic.swift       # Communication topics
│   ├── MeTopic.swift        # User's own topic
│   ├── FndTopic.swift       # Find/search topics
│   └── User.swift           # User management
├── Communication
│   ├── WebSocket.swift      # WebSocket implementation
│   ├── PromisedReply.swift  # Async message handling
│   └── AuthScheme.swift     # Authentication schemes
├── Utilities
│   ├── Storage.swift        # Data persistence
│   ├── Log.swift           # Logging utilities
│   └── RFC3339Format.swift  # Date formatting
└── Model Objects
    ├── ClientMessages.swift  # Client-side message types
    ├── ServerMessages.swift  # Server-side message types
    ├── Drafty.swift         # Rich text formatting
    ├── Acs.swift            # Access control
    ├── Description.swift    # Entity descriptions
    ├── Subscription.swift   # Topic subscriptions
    ├── TheCard.swift        # User cards/profiles
    ├── Types.swift          # Common type definitions
    └── JSONValue.swift      # JSON utilities
```

#### 2. **Tinodios** - iOS Application Layer
```
Tinodios/
├── Application Lifecycle
│   └── AppDelegate.swift             # App delegate & Firebase config
├── Chat Interface
│   ├── ChatListViewController.swift   # Chat list view
│   ├── ChatListPresenter.swift       # Chat list business logic
│   ├── ChatListInteractor.swift     # Chat list data handling
│   ├── ChatListRouter.swift         # Chat list navigation
│   ├── MessageViewController.swift   # Message conversation view
│   ├── MessagePresenter.swift       # Message business logic
│   ├── MessageInteractor.swift      # Message data handling
│   └── MessageView.swift            # Message UI components
├── Authentication & User Management
│   ├── CredentialsViewController.swift     # Login interface
│   ├── SignupViewController.swift          # Registration interface
│   ├── ResetPasswordViewController.swift   # Password reset
│   └── CredentialsChangeViewController.swift # Change credentials
├── User Interface & Settings
│   ├── AccountSettingsViewController.swift      # Account settings
│   ├── AccountGeneralSettingsViewController.swift # General settings
│   ├── SettingsNotificationsViewController.swift # Notification settings
│   ├── SettingsSecurityViewController.swift    # Security settings
│   └── SettingsHelpViewController.swift        # Help interface
├── Communication Features
│   ├── FindViewController.swift        # Find users/contacts
│   ├── FindPresenter.swift            # Find business logic
│   ├── FindInteractor.swift           # Find data handling
│   ├── ForwardToViewController.swift   # Message forwarding
│   ├── NewGroupViewController.swift    # Group creation
│   └── EditMembersViewController.swift # Group member management
├── Media & Files
│   ├── CallViewController.swift        # Video/audio calls
│   ├── CallManager.swift              # Call state management
│   ├── CallProviderDelegate.swift     # CallKit integration
│   ├── MediaRecorder.swift            # Audio recording
│   ├── RecordedMediaPlayback.swift    # Media playback
│   ├── ImagePreviewController.swift   # Image preview
│   ├── VideoPreviewController.swift   # Video preview
│   ├── FilePreviewController.swift    # File preview
│   └── LargeFileHelper.swift          # Large file handling
├── Specialized Components
│   ├── QRScanner.swift                # QR code scanning
│   ├── BrandingViewController.swift    # App branding
│   ├── ArchivedChatsTableViewController.swift # Archived chats
│   ├── BlockedContactsTableViewController.swift # Blocked contacts
│   └── TopicInfoViewController.swift   # Topic information
└── Utilities & Helpers
    ├── Cache.swift                    # Caching utilities
    ├── UiUtils.swift                  # UI helper functions
    ├── Utils.swift                    # General utilities
    ├── KeyboardInfo.swift             # Keyboard handling
    └── MessageViewLayout.swift        # Message layout
```

#### 3. **Specialized Modules**

##### Contact Management
```
Tinodios/account/
├── ContactsManager.swift      # iOS Contacts integration
└── ContactsSynchronizer.swift # Contact sync functionality
```

##### Rich Text Formatting
```
Tinodios/format/
├── AbstractFormatter.swift        # Base formatting
├── FullFormatter.swift           # Complete rich text
├── PreviewFormatter.swift        # Message previews
├── QuoteFormatter.swift          # Quote formatting
├── SendReplyFormatter.swift      # Reply formatting
├── SendForwardedFormatter.swift  # Forward formatting
├── FormatNode.swift              # Format tree nodes
├── AsyncImageTextAttachment.swift # Async image loading
├── ButtonAttachment.swift        # Interactive buttons
├── EntityTextAttachment.swift    # Entity attachments
├── MultiImageTextAttachment.swift # Multiple images
├── QuotedAttachment.swift        # Quote attachments
├── WaveTextAttachment.swift      # Audio waveforms
└── ThumbnailTransformer.swift    # Image thumbnails
```

##### UI Widgets
```
Tinodios/widgets/
├── AvatarWithOnlineIndicator.swift     # User avatars with status
├── ChatListViewCell.swift             # Chat list cells
├── ContactViewCell.swift              # Contact list cells
├── DotSelectorImageView.swift          # Multi-selection UI
├── MessageCell.swift                   # Message cells
├── MessageBubbleDecorator.swift       # Message styling
├── SendMessageBar.swift               # Message input bar
├── RichTextView.swift                  # Rich text display
├── MessageCellProtocols.swift          # Cell protocols
└── Various other UI components...
```

---

## 📱 Features & Capabilities

### ✅ Implemented Features

#### Core Messaging
- ✅ One-on-one conversations
- ✅ Group chats & channels
- ✅ Message status indicators (sent/delivered/read)
- ✅ Rich text formatting (Markdown-style)
- ✅ Message replies & forwarding
- ✅ Message pinning
- ✅ Unread message counters

#### Media & Attachments
- ✅ Image attachments & inline images
- ✅ Voice/audio messages
- ✅ File attachments
- ✅ Media preview & playback

#### Communication
- ✅ Video calling (one-on-one)
- ✅ Audio calling (one-on-one)
- ✅ WebRTC integration
- ✅ CallKit integration (iOS)

#### User Management
- ✅ User authentication
- ✅ Contact integration (iOS Contacts)
- ✅ Find & invite users
- ✅ User profiles & avatars
- ✅ Trusted account badges
- ✅ Blocking & permissions

#### Platform Integration
- ✅ Push notifications (Firebase)
- ✅ Background modes (VoIP, fetch, processing)
- ✅ Transport Layer Security (TLS)
- ✅ Offline mode support
- ✅ SMS/email invitations

#### Localization
- ✅ English (default)
- ✅ Spanish (es)
- ✅ Russian (ru)
- ✅ Ukrainian (uk)
- ✅ Chinese Simplified (zh-Hans)
- ✅ Chinese Traditional (zh-Hant)

### ⏳ Planned Features

#### Media Enhancements
- ⏳ Video previews for attachments
- ⏳ Link previews
- ⏳ Document previews
- ⏳ Video messages

#### Communication Features
- ⏳ Typing indicators
- ⏳ Multi-backend support
- ⏳ Mentions & hashtags
- ⏳ End-to-end encryption

---

## 🔧 Dependencies & Frameworks

### Core Dependencies (Podfile)

#### Database & Storage
- **SQLite.swift** `~> 0.15` - SQLite database wrapper
- **SwiftKeychainWrapper** `~> 3` - Keychain access utilities

#### Firebase Services
- **Firebase** - Core Firebase SDK
- **FirebaseCore** - Firebase foundation
- **FirebaseMessaging** - Push notifications
- **FirebaseAnalytics** - App analytics
- **FirebaseCrashlytics** - Crash reporting

#### Media & Communication
- **Kingfisher** `~> 5` - Image loading & caching
- **MobileVLCKit** `~> 3` - Audio/video playback
- **PhoneNumberKit** `~> 4` - Phone number validation
- **WebRTC-lib** `~> 139.0.0` - Video/audio calling

### iOS Framework Integration
- **CallKit** - Native call interface
- **Contacts** - iOS contact integration
- **UserNotifications** - Push notification handling
- **AVFoundation** - Media recording/playback
- **Photos** - Photo library access
- **MessageUI** - SMS/email composition

---

## 📁 Project Structure

```
qixsecure-bcp/
├── 📂 TinodeSDK/                    # Core messaging SDK
│   ├── 📂 model/                    # Data models
│   └── 📄 Various Swift files       # SDK implementation
├── 📂 TinodiosDB/                   # Database project
├── 📂 Tinodios/                     # Main iOS application
│   ├── 📂 account/                  # Contact management
│   ├── 📂 format/                   # Rich text formatting
│   ├── 📂 widgets/                  # UI components
│   ├── 📂 Base.lproj/              # Storyboards & XIBs
│   ├── 📂 Supporting Files/         # Assets & resources
│   ├── 📂 Settings.bundle/          # App settings
│   └── 📄 Various Swift files       # View controllers & logic
├── 📂 TinodeSDKTests/               # SDK unit tests
├── 📂 Localizations/                # Localization files
├── 📂 Pods/                         # CocoaPods dependencies
├── 📄 Podfile                       # Dependency configuration
├── 📄 *.xcodeproj                   # Xcode project files
├── 📄 *.xcconfig                    # Build configurations
└── 📄 Supporting files              # README, LICENSE, etc.
```

---

## ⚙️ Configuration & Setup

### Build Configurations

#### Development Configuration (`devel.xcconfig`)
- **Server**: `fochat-dev.saleswarp.com`
- **TLS**: Enabled
- **Version**: Based on Git tags
- **API Key**: Development key

#### Production Configuration (`prod.xcconfig`)
- **Server**: `fochat-dev.saleswarp.com`
- **TLS**: Enabled
- **Version**: Auto-updated by build scripts
- **API Key**: Production key

### Setup Requirements

1. **CocoaPods Installation**
   ```bash
   # Standard installation
   pod install

   # Apple Silicon (M1) systems
   arch -x86_64 pod install
   ```

2. **Firebase Configuration**
   - Place `GoogleService-Info.plist` in `Tinodios/` folder
   - Configure Firebase project for push notifications

3. **Development Environment**
   - Xcode 12.0+
   - iOS 14.0+ deployment target
   - Swift 5.0+

---

## 🚀 Getting Started

### Installation Steps

1. **Clone Repository**
   ```bash
   git clone [repository-url]
   cd qixsecure-bcp
   ```

2. **Install Dependencies**
   ```bash
   pod install
   ```

3. **Configure Firebase**
   - Obtain `GoogleService-Info.plist` from Firebase console
   - Place in `Tinodios/` directory

4. **Open Project**
   ```bash
   open Tinodios.xcworkspace
   ```

5. **Build & Run**
   - Select target device/simulator
   - Build and run project

### Development Workflow

1. **Project Structure**: Use Xcode workspace (`Tinodios.xcworkspace`)
2. **Configuration**: Edit `.xcconfig` files for environment settings
3. **Dependencies**: Manage via `Podfile` and CocoaPods
4. **Localization**: Add strings to appropriate `.lproj` folders
5. **Testing**: Run tests via `TinodeSDKTests` target

---

## 📞 Support & Resources

### Documentation
- [Tinode Server API](https://github.com/tinode/chat/blob/master/docs/API.md)
- [iOS Translation Guide](https://github.com/tinode/chat/blob/devel/docs/translations.md#ios)

### Community & Support
- **Forum**: [Google Groups](https://groups.google.com/d/forum/tinode)
- **Issues**: [GitHub Issues](https://github.com/tinode/ios/issues/new)
- **Commercial**: https://tinode.co/contact

### Contributing
- **Beta Testing**: Email `testflight @ tinode . co`
- **Pull Requests**: Submit bug fixes and features
- **Translations**: Help localize the app
- **UI/UX**: Improve app design and usability

---

## 📊 Project Metrics

| Metric | Count |
|--------|-------|
| **Swift Files** | ~80+ files |
| **View Controllers** | ~30+ controllers |
| **Supported Languages** | 6 languages |
| **Dependencies** | 12 main pods |
| **iOS Version Support** | iOS 14.0+ |
| **Project Targets** | 4 targets |

---

*Last Updated: Generated via Claude Code SuperClaude framework*
*Project Status: Active Development - Beta Release Ready*