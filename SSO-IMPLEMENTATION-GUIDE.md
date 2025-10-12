# SSO Authentication Implementation Guide

**QixSecure BCP - iOS SSO Integration**

---

## 🔍 **Current Authentication Architecture**

### **iOS Implementation Structure**
```swift
// Current login methods in TinodeSDK/Tinode.swift:
loginBasic(uname: String, password: String) -> PromisedReply<ServerMessage>
loginToken(token: String, creds: [Credential]?) -> PromisedReply<ServerMessage>
login(scheme: String, secret: String, creds: [Credential]?) -> PromisedReply<ServerMessage>
```

### **Web vs iOS Authentication Comparison**

| Aspect | Web Implementation | iOS Implementation |
|--------|-------------------|-------------------|
| **Basic Login** | `tinode.login('basic', b64EncodeUnicode("username:password"))` | `loginBasic(uname: userName, password: password)` |
| **Token Login** | `tinode.login('token', token)` | `loginToken(token: token, creds: nil)` |
| **SSO (Desired)** | `tinode.login('sso', b64EncodeUnicode(token))` | **Missing - needs implementation** |

### **Current AuthScheme Support**
```swift
// TinodeSDK/AuthScheme.swift - Line 14-17:
static let kLoginBasic = "basic"
static let kLoginToken = "token"
static let kLoginReset = "reset"
static let kLoginCode  = "code"
// Missing: kLoginSSO = "sso"
```

---

## 🛠️ **SSO Implementation Strategy**

### **1. AuthScheme Updates** (`TinodeSDK/AuthScheme.swift`)

**Add SSO constant:**
```swift
static let kLoginSSO = "sso"
```

**Add SSO helper method:**
```swift
static func ssoInstance(token: String) -> AuthScheme {
    return AuthScheme(scheme: kLoginSSO, secret: token.toBase64()!)
}
```

**Update parse method** to recognize SSO:
```swift
// Line 32 - Update validation:
if scheme == kLoginBasic || scheme == kLoginToken || scheme == kLoginSSO {
    return AuthScheme(scheme: scheme, secret: String(parts[1]))
}
```

### **2. Tinode SDK Extension** (`TinodeSDK/Tinode.swift`)

**Add SSO login method:**
```swift
public func loginSSO(token: String) -> PromisedReply<ServerMessage> {
    let encodedToken = token.toBase64() ?? token
    return login(scheme: AuthScheme.kLoginSSO, secret: encodedToken, creds: nil)
}
```

**Update auto-login support:**
```swift
public func setAutoLoginWithSSO(token: String) {
    setAutoLogin(using: AuthScheme.kLoginSSO, authenticateWith: token.toBase64() ?? token)
}
```

### **3. UI Integration** (`Tinodios/LoginViewController.swift`)

**Add SSO button & flow:**
```swift
@IBAction func ssoLoginClicked(_ sender: Any) {
    // Get token from your SSO provider
    let ssoToken = obtainSSOToken() // Your implementation

    guard !ssoToken.isEmpty else { return }

    let tinode = Cache.tinode
    UiUtils.toggleProgressOverlay(in: self, visible: true, title: "SSO Login...")

    do {
        try tinode.connectDefault(inBackground: false)?
            .thenApply({ _ in
                return tinode.loginSSO(token: ssoToken)
            })
            .then(onSuccess: { [weak self] pkt in
                // Handle success - same as loginBasic
                self?.handleLoginSuccess(pkt: pkt, tinode: tinode)
                return nil
            }, onFailure: { err in
                // Handle failure
                self?.handleLoginFailure(err: err)
                return nil
            })
    } catch {
        handleConnectionError(error)
    }
}

private func handleLoginSuccess(pkt: ServerMessage?, tinode: Tinode) {
    Cache.log.info("LoginVC - SSO login successful for %@", tinode.myUid!)
    SharedUtils.saveAuthToken(for: "sso_user", token: tinode.authToken, expires: tinode.authTokenExpires)
    if let token = tinode.authToken {
        tinode.setAutoLoginWithSSO(token: token)
    }
    if let ctrl = pkt?.ctrl, ctrl.code >= 300, ctrl.text.contains("validate credentials") {
        DispatchQueue.main.async {
            UiUtils.routeToCredentialsVC(in: self.navigationController,
                                       verifying: ctrl.getStringArray(for: "cred")?.first)
        }
        return
    }
    UiUtils.routeToChatListVC()
}

private func handleLoginFailure(err: Error) {
    Cache.log.error("LoginVC - SSO login failed: %@", err.localizedDescription)
    var toastMsg: String
    if let tinodeErr = err as? TinodeError {
        toastMsg = "SSO Login Failed: \(tinodeErr.description)"
    } else {
        let (hostName, _) = Tinode.getConnectionParams()
        toastMsg = String(format: NSLocalizedString("SSO connection failed to %@: %@", comment: "SSO Error"), hostName, err.localizedDescription)
    }
    DispatchQueue.main.async {
        UiUtils.showToast(message: toastMsg)
    }
    Cache.invalidate()
}
```

---

## 📝 **Required Code Changes**

### **File Modifications Required:**

#### **1. TinodeSDK/AuthScheme.swift**

**Location: Lines 14-17**
```swift
// EXISTING:
static let kLoginBasic = "basic"
static let kLoginToken = "token"
static let kLoginReset = "reset"
static let kLoginCode  = "code"

// ADD:
static let kLoginSSO = "sso"
```

**Location: Line 32**
```swift
// EXISTING:
if scheme == kLoginBasic || scheme == kLoginToken {

// UPDATE TO:
if scheme == kLoginBasic || scheme == kLoginToken || scheme == kLoginSSO {
```

**Location: Add after line 77**
```swift
// ADD new method:
static func ssoInstance(token: String) -> AuthScheme {
    return AuthScheme(scheme: kLoginSSO, secret: token.toBase64()!)
}
```

#### **2. TinodeSDK/Tinode.swift**

**Location: Add after line 936 (after loginToken method)**
```swift
// ADD SSO login method:
public func loginSSO(token: String) -> PromisedReply<ServerMessage> {
    let encodedToken = token.toBase64() ?? token
    return login(scheme: AuthScheme.kLoginSSO, secret: encodedToken, creds: nil)
}
```

**Location: Add after line 921 (after setAutoLoginWithToken)**
```swift
// ADD SSO auto-login method:
public func setAutoLoginWithSSO(token: String) {
    setAutoLogin(using: AuthScheme.kLoginSSO, authenticateWith: token.toBase64() ?? token)
}
```

#### **3. Tinodios/LoginViewController.swift**

**UI Updates Needed:**
- Add SSO button to Main.storyboard
- Connect button to new `ssoLoginClicked` action
- Implement SSO token acquisition logic

**Add after existing login methods:**
```swift
@IBAction func ssoLoginClicked(_ sender: Any) {
    // Implementation provided above
}

private func obtainSSOToken() -> String {
    // TODO: Implement your SSO provider integration
    // This could be OAuth, SAML, or custom SSO token retrieval
    return "" // Replace with actual token acquisition
}
```

---

## ⚡ **Implementation Benefits**

### **✅ Advantages**
- **Consistent API**: Matches web implementation pattern exactly
- **Reuses Existing Infrastructure**: Leverages current login flow
- **Minimal Changes**: Only 3 files need modification
- **Backward Compatible**: Doesn't break existing auth methods
- **Base64 Encoding**: Consistent with web implementation

### **🔧 Integration Points**
- **Token Provider**: Need to implement `obtainSSOToken()` method
- **UI Updates**: Add SSO button/flow to login screen
- **Error Handling**: Reuse existing login error patterns
- **Auto-Login**: SSO tokens can be cached like other auth methods

### **📋 Implementation Checklist**

#### **Phase 1: Core SDK Changes**
- [ ] Add `kLoginSSO` constant to AuthScheme.swift
- [ ] Update AuthScheme parse method for SSO support
- [ ] Add `ssoInstance` helper method
- [ ] Add `loginSSO` method to Tinode.swift
- [ ] Add `setAutoLoginWithSSO` method

#### **Phase 2: UI Integration**
- [ ] Add SSO button to login storyboard
- [ ] Implement `ssoLoginClicked` action method
- [ ] Add SSO token acquisition logic
- [ ] Update login error handling for SSO
- [ ] Test SSO login flow

#### **Phase 3: Testing & Validation**
- [ ] Unit tests for SSO AuthScheme methods
- [ ] Integration tests for SSO login flow
- [ ] End-to-end testing with actual SSO provider
- [ ] Error scenario testing
- [ ] Auto-login testing with SSO tokens

---

## 🔗 **Integration with SSO Providers**

### **Common SSO Integration Patterns**

#### **OAuth 2.0 / OpenID Connect**
```swift
private func obtainSSOToken() -> String {
    // Example with OAuth provider
    let authURL = "https://your-sso-provider.com/oauth/authorize"
    // Implement OAuth flow and return access token
    return oauthAccessToken
}
```

#### **SAML Integration**
```swift
private func obtainSSOToken() -> String {
    // Example with SAML provider
    // Implement SAML assertion processing
    return samlToken
}
```

#### **Custom SSO Provider**
```swift
private func obtainSSOToken() -> String {
    // Example with custom SSO
    // Implement your custom authentication flow
    return customSSOToken
}
```

---

## 🚨 **Security Considerations**

### **Token Security**
- **Encryption**: Ensure SSO tokens are encrypted in transit
- **Storage**: Use iOS Keychain for secure token storage
- **Expiration**: Implement proper token expiration handling
- **Validation**: Validate tokens on both client and server side

### **Implementation Security**
```swift
// Example secure token handling
private func securelyStoreSSO Token(_ token: String) {
    let keychain = SwiftKeychainWrapper.standard
    keychain.set(token, forKey: "sso_token")
}

private func retrieveSecureSSO Token() -> String? {
    let keychain = SwiftKeychainWrapper.standard
    return keychain.string(forKey: "sso_token")
}
```

---

## 📖 **Next Steps**

1. **Implement Core Changes**: Apply the code modifications to the 3 files
2. **Design SSO UI**: Add SSO button and user flow to login screen
3. **SSO Provider Integration**: Implement your specific SSO token acquisition
4. **Testing**: Comprehensive testing of SSO login flow
5. **Documentation**: Update app documentation with SSO login instructions

The implementation follows the exact pattern from your web version:
- **Web**: `tinode.login('sso', b64EncodeUnicode(token))`
- **iOS**: `tinode.loginSSO(token: token)`

This maintains consistency across platforms while leveraging iOS-specific patterns and security features.

---

*Generated by Claude Code SuperClaude Framework*
*Project: QixSecure BCP - iOS SSO Authentication Implementation*