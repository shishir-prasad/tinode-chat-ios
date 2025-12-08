//
//  SharedUtils.swift
//  TinodiosDB
//
//  Copyright © 2020-2022 Tinode. All rights reserved.
//

import Foundation
import SwiftKeychainWrapper
import TinodeSDK

public class SharedUtils {
    static public let kNotificationBrandingSmallIconAvailable = "BrandingSmallIconAvailable"
    static public let kNotificationBrandingConfigAvailable = "BrandingConfigAvailable"

    static public let kTinodeMetaVersion = "tinodeMetaVersion"

    static public let kTinodePrefLastLogin = "tinodeLastLogin"
    static public let kTinodePrefReadReceipts = "tinodePrefSendReadReceipts"
    static public let kTinodePrefTypingNotifications = "tinodePrefTypingNoficications"
    static public let kTinodePrefAppLaunchedBefore = "tinodePrefAppLaunchedBefore"

    static public let kTinodePrefTosUrl = "tinodePrefTosUrl"
    static public let kTinodePrefServiceName = "tinodePrefServiceName"
    static public let kTinodePrefPrivacyUrl = "tinodePrefPrivacyUrl"
    static public let kTinodePrefAppId = "tinodePrefAppId"
    static public let kTinodePrefSmallIcon = "tinodePrefSmallIcon"
    static public let kTinodePrefLargeIcon = "tinodePrefLargeIcon"
    static public let kPrefHostName = "host_name_preference"
    static public let kPrefUseTLS = "use_tls_preference"

    // App Tinode api key.
    private static let kApiKey = "AQAAAAABAAByCoXpLdVgii7-77YqZ6S4"

    static public let kAppDefaults = UserDefaults(suiteName: BaseDb.kAppGroupId)!
    static let kAppKeychain = KeychainWrapper(serviceName: "co.tinode.tinodios", accessGroup: BaseDb.kAppGroupId)

    // Keys we store in keychain.
    static let kTokenKey = "co.tinode.token"
    static let kTokenExpiryKey = "co.tinode.token_expiry"

    // Auto logout control flag.
    // Set to false to disable automatic logout on authentication errors.
    // Manual logout will still work through user interface.
    public static let kEnableAutoLogout: Bool = true

    // Application metadata version.
    // Bump it up whenever you change the application metadata and
    // want to force the user to re-login when the user installs
    // this new application version.
    static let kAppMetaVersion = 1

    // Default connection params.
    #if DEBUG
        public static let kDefaultHostName = "127.0.0.1:6060" // localhost
        public static let kDefaultUseTLS = false
    #else
        public static let kDefaultHostName = "api.tinode.co" // production cluster
        public static let kDefaultUseTLS = true
    #endif

    // Returns true if the app is being launched for the first time.
    public static var isFirstLaunch: Bool {
        get {
            return !SharedUtils.kAppDefaults.bool(forKey: SharedUtils.kTinodePrefAppLaunchedBefore)
        }
        set {
            SharedUtils.kAppDefaults.set(!newValue, forKey: SharedUtils.kTinodePrefAppLaunchedBefore)
        }
    }

    // App TOS url string.
    public static var tosUrl: String? {
        get {
            return SharedUtils.kAppDefaults.string(forKey: SharedUtils.kTinodePrefTosUrl)
        }
        set {
            SharedUtils.kAppDefaults.set(newValue, forKey: SharedUtils.kTinodePrefTosUrl)
        }
    }

    // Application service name.
    public static var serviceName: String? {
        get {
            return SharedUtils.kAppDefaults.string(forKey: SharedUtils.kTinodePrefServiceName)
        }
        set {
            SharedUtils.kAppDefaults.set(newValue, forKey: SharedUtils.kTinodePrefServiceName)
        }
    }

    // Application privacy policy url.
    public static var privacyUrl: String? {
        get {
            return SharedUtils.kAppDefaults.string(forKey: SharedUtils.kTinodePrefPrivacyUrl)
        }
        set {
            SharedUtils.kAppDefaults.set(newValue, forKey: SharedUtils.kTinodePrefPrivacyUrl)
        }
    }

    // App's registration id in Tinode console.
    public static var appId: String? {
        get {
            return SharedUtils.kAppDefaults.string(forKey: SharedUtils.kTinodePrefAppId)
        }
        set {
            SharedUtils.kAppDefaults.set(newValue, forKey: SharedUtils.kTinodePrefAppId)
        }
    }

    // Apps' small icon.
    public static var smallIcon: UIImage? {
        get {
            if let data = SharedUtils.kAppDefaults.object(forKey: SharedUtils.kTinodePrefSmallIcon) as? Data {
                return UIImage(data: data)
            }
            return nil
        }
        set {
            SharedUtils.kAppDefaults.set(newValue?.pngData(), forKey: SharedUtils.kTinodePrefSmallIcon)
        }
    }

    // Apps' large icon.
    public static var largeIcon: UIImage? {
        get {
            if let data = SharedUtils.kAppDefaults.object(forKey: SharedUtils.kTinodePrefLargeIcon) as? Data {
                return UIImage(data: data)
            }
            return nil
        }
        set {
            SharedUtils.kAppDefaults.set(newValue?.pngData(), forKey: SharedUtils.kTinodePrefLargeIcon)
        }
    }

    public static func getSavedLoginUserName() -> String? {
        return SharedUtils.kAppDefaults.string(forKey: SharedUtils.kTinodePrefLastLogin)
    }
    private static func appMetaVersionUpToDate() -> Bool {
        let v = SharedUtils.kAppDefaults.integer(forKey: SharedUtils.kTinodeMetaVersion)
        guard v == SharedUtils.kAppMetaVersion else {
            BaseDb.log.error("App meta version does not match. Saved [%d] vs current [%d]", v, SharedUtils.kAppMetaVersion)
            // Clear the app keychain.
            SharedUtils.kAppKeychain.removeAllKeys()
            SharedUtils.kAppDefaults.set(SharedUtils.kAppMetaVersion, forKey: SharedUtils.kTinodeMetaVersion)
            return false
        }
        return true
    }

    public static func getAuthToken() -> String? {
        guard SharedUtils.appMetaVersionUpToDate() else { return nil }

        // Check keychain accessibility before attempting to read
        guard isKeychainAccessible() else {
            BaseDb.log.info("Keychain not accessible, cannot retrieve auth token")
            return nil
        }

        return SharedUtils.kAppKeychain.string(
            forKey: SharedUtils.kTokenKey, withAccessibility: .afterFirstUnlock)
    }

    private static func isKeychainAccessible() -> Bool {
        // Test keychain accessibility by attempting to read/write a test value
        let testKey = "co.tinode.accessibility_test"
        let testValue = "test_\(Date().timeIntervalSince1970)"

        // Try to set a test value
        guard SharedUtils.kAppKeychain.set(testValue, forKey: testKey, withAccessibility: .afterFirstUnlock) else {
            BaseDb.log.debug("Keychain accessibility test failed - cannot write")
            return false
        }

        // Try to read the test value
        let retrievedValue = SharedUtils.kAppKeychain.string(forKey: testKey, withAccessibility: .afterFirstUnlock)

        // Clean up test value
        SharedUtils.kAppKeychain.removeObject(forKey: testKey)

        let isAccessible = retrievedValue == testValue
        if !isAccessible {
            BaseDb.log.debug("Keychain accessibility test failed - read/write mismatch")
        }

        return isAccessible
    }

    public static func getAuthTokenExpiryDate() -> Date? {
        // Check keychain accessibility before attempting to read
        guard isKeychainAccessible() else {
            BaseDb.log.info("Keychain not accessible, cannot retrieve auth token expiry date")
            return nil
        }

        guard let expString = SharedUtils.kAppKeychain.string(
            forKey: SharedUtils.kTokenExpiryKey, withAccessibility: .afterFirstUnlock) else { return nil }
        return Formatter.rfc3339.date(from: expString)
    }

    public static func removeAuthToken() {
        SharedUtils.kAppDefaults.removeObject(forKey: SharedUtils.kTinodePrefLastLogin)
        SharedUtils.kAppKeychain.removeAllKeys()
    }

    public static func saveAuthToken(for userName: String, token: String?, expires expiryDate: Date?) {
        saveAuthToken(for: userName, token: token, expires: expiryDate, completion: nil)
    }

    public static func saveAuthToken(for userName: String, token: String?, expires expiryDate: Date?, completion: ((Bool) -> Void)?) {
        var success = true

        // Save username to user defaults
        SharedUtils.kAppDefaults.set(userName, forKey: SharedUtils.kTinodePrefLastLogin)

        if let token = token, !token.isEmpty {
            // Save token to keychain with validation
            if !SharedUtils.kAppKeychain.set(token, forKey: SharedUtils.kTokenKey, withAccessibility: .afterFirstUnlock) {
                BaseDb.log.error("Could not save auth token to keychain")
                success = false
            } else {
                // Retry validation with small delay to handle async keychain writes
                // iOS keychain writes may not be immediately readable due to async persistence
                var validationSuccess = false
                for attempt in 1...3 {
                    if let retrievedToken = SharedUtils.kAppKeychain.string(forKey: SharedUtils.kTokenKey, withAccessibility: .afterFirstUnlock),
                       retrievedToken == token {
                        validationSuccess = true
                        BaseDb.log.debug("Auth token validation succeeded on attempt %d", attempt)
                        break
                    }
                    // Wait briefly before retrying (10ms, 20ms, 30ms progression)
                    if attempt < 3 {
                        Thread.sleep(forTimeInterval: Double(attempt) * 0.01)
                        BaseDb.log.debug("Auth token validation retry %d", attempt)
                    }
                }

                if !validationSuccess {
                    BaseDb.log.error("Auth token validation failed after 3 attempts")
                    success = false
                }
            }

            // Save expiry date if provided
            if let expiryDate = expiryDate {
                let expiryString = Formatter.rfc3339.string(from: expiryDate)
                if !SharedUtils.kAppKeychain.set(expiryString, forKey: SharedUtils.kTokenExpiryKey, withAccessibility: .afterFirstUnlock) {
                    BaseDb.log.error("Could not save auth token expiry date")
                    success = false
                }
            } else {
                SharedUtils.kAppKeychain.removeObject(forKey: SharedUtils.kTokenExpiryKey)
            }
        }

        // Force sync to ensure persistence
        SharedUtils.kAppDefaults.synchronize()

        // Call completion handler with result
        completion?(success)

        if success {
            BaseDb.log.info("Auth token saved and validated successfully for user: %@", userName)
        } else {
            BaseDb.log.error("Failed to save or validate auth token for user: %@", userName)
        }
    }

    /// Creates a Tinode instance backed by the local starage.
    public static func createTinode() -> Tinode {
        let appVersion: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        let appName = "Tinodios/" + appVersion
        let dbh = BaseDb.sharedInstance
        // FIXME: Get and use current UI language from Bundle.main.preferredLocalizations.first
        let tinode = Tinode(for: appName,
                            authenticateWith: SharedUtils.kApiKey,
                            persistDataIn: dbh.sqlStore)
        tinode.OsVersion = UIDevice.current.systemVersion
        return tinode
    }

    public static func registerUserDefaults() {
        // Give default values to UserDefault keys.
        kAppDefaults.register(defaults: [
            kTinodePrefReadReceipts: true,
            kTinodePrefTypingNotifications: true
        ])

        // Make sure changes are copied.
        syncUserDefaults()

        let (hostName, _) = getConnectionSettings()
        if hostName == nil {
            // If hostname is nil, sync values to defaults
            setConnectionSettings(Bundle.main.object(forInfoDictionaryKey: "HOST_NAME") as? String, Bundle.main.object(forInfoDictionaryKey: "USE_TLS") as? String)
        }
        if !appMetaVersionUpToDate() {
            BaseDb.log.info("App started for the first time.")
        }
    }

    /// Copy values from UserDefaults.standard to kAppDefaults.
    public static func syncUserDefaults() {
        let settingsKeys = [
            kPrefHostName,
            kPrefUseTLS
        ]

        for key in settingsKeys {
            if let value = UserDefaults.standard.object(forKey: key) {
                kAppDefaults.set(value, forKey: key)
            }
        }
    }

    public static func connectAndLoginSync(using tinode: Tinode, inBackground bkg: Bool) -> Bool {
        guard let userName = SharedUtils.getSavedLoginUserName(), !userName.isEmpty else {
            BaseDb.log.error("Connect&Login Sync - missing user name")
            return false
        }
        guard let token = SharedUtils.getAuthToken(), !token.isEmpty else {
            BaseDb.log.error("Connect&Login Sync - missing auth token")
            return false
        }
        // NEW: More flexible token handling
        if SharedUtils.kEnableAutoLogout {
            if let tokenExpires = SharedUtils.getAuthTokenExpiryDate(), tokenExpires < Date() {
                // Token has expired.
                BaseDb.log.error("Connect&Login Sync - auth token expired")
                return false
            }
        } else {
            // When auto-logout is disabled, be more tolerant of token issues
            if let tokenExpires = SharedUtils.getAuthTokenExpiryDate(), tokenExpires < Date() {
                BaseDb.log.info("Connect&Login Sync - token expired but auto-logout disabled, attempting anyway")
                // Continue with connection attempt - server might refresh the token
            }
        }
        BaseDb.log.info("Connect&Login Sync - will attempt to login (user name: %@)", userName)
        var success = false
        do {
            tinode.setAutoLoginWithSSO(token: token)
            // Tinode.connect() will automatically log in.
            let msg = try tinode.connectDefault(inBackground: bkg)?.getResult()
            if let ctrl = msg?.ctrl {
                // Assuming success by default.
                success = true
                switch ctrl.code {
                case 0..<300:
                    let myUid = ctrl.getStringParam(for: "user")
                    BaseDb.log.info("Connect&Login Sync - login successful for: %@", myUid!)
                    if tinode.authToken != token {
                        SharedUtils.saveAuthToken(for: userName, token: tinode.authToken, expires: tinode.authTokenExpires)
                    }
                case 401:
                    // NEW: Handle 401 more gracefully
                    BaseDb.log.info("Connect&Login Sync - 401 unauthorized, may need token refresh")
                    success = !SharedUtils.kEnableAutoLogout // Allow app to continue if auto-logout disabled
                case 409:
                    BaseDb.log.info("Connect&Login Sync - already authenticated.")
                case 500..<600:
                    BaseDb.log.error("Connect&Login Sync - server error on login: %d", ctrl.code)
                    success = false
                default:
                    success = false
                }
            }
        } catch WebSocketError.network(let err) {
            BaseDb.log.debug("Connect&Login Sync [network] - could not connect to Tinode: %@", err)
            // NEW: Return true for network errors when auto-logout disabled - app can retry later
            success = !SharedUtils.kEnableAutoLogout
        } catch {
            let err = error as NSError
            if err.code == NSURLErrorCannotConnectToHost {
                BaseDb.log.debug("Connect&Login Sync [network] - could not connect to Tinode: %@", err)
                success = !SharedUtils.kEnableAutoLogout
            } else {
                BaseDb.log.error("Connect&Login Sync - failed to automatically login to Tinode: %@", error.localizedDescription)
                // NEW: More tolerant error handling
                success = !SharedUtils.kEnableAutoLogout
            }
        }
        return success
    }

    static func getConnectionSettings() -> (hostName: String?, useTLS: Bool?) {
        return (hostName: kAppDefaults.string(forKey: kPrefHostName), useTLS: kAppDefaults.bool(forKey: kPrefUseTLS))
    }

    static func setConnectionSettings(_ hostName: String?, _ useTLS: String?) {
        if hostName != nil {
            kAppDefaults.set(hostName, forKey: kPrefHostName)
            UserDefaults.standard.set(hostName, forKey: kPrefHostName)
        }
        if useTLS != nil {
            kAppDefaults.set(useTLS, forKey: kPrefUseTLS)
            UserDefaults.standard.set(useTLS, forKey: kPrefUseTLS)
        }
    }

    // Synchronously fetches description for topic |topicName|
    // (and saves the description locally).
    @discardableResult
    public static func fetchDesc(using tinode: Tinode, for topicName: String) -> UIBackgroundFetchResult {
        guard tinode.isConnectionAuthenticated || SharedUtils.connectAndLoginSync(using: tinode, inBackground: true) else {
            return .failed
        }
        // If we have topic data, we are done.
        guard !tinode.isTopicTracked(topicName: topicName) else {
            return .noData
        }
        do {
            if let msg = try tinode.getMeta(topic: topicName, query: MsgGetMeta.desc()).getResult(),
                (msg.ctrl?.code ?? 500) < 300 {
                return .newData
            }
        } catch {
            BaseDb.log.error("Failed to fetch topic description for [%@]: %@", topicName, error.localizedDescription)
        }
        return .failed
    }

    // Synchronously connects to topic |topicName| and fetches its messages
    // if the last received message was prior to |seq|.
    @discardableResult
    public static func fetchData(using tinode: Tinode, for topicName: String, seq: Int, keepConnection: Bool) -> UIBackgroundFetchResult {
        guard tinode.isConnectionAuthenticated || SharedUtils.connectAndLoginSync(using: tinode, inBackground: true) else {
            return .failed
        }
        var topic: DefaultComTopic
        var builder: DefaultComTopic.MetaGetBuilder
        if !tinode.isTopicTracked(topicName: topicName) {
            // New topic. Create it.
            guard let t = tinode.newTopic(for: topicName) as? DefaultComTopic else {
                return .failed
            }
            topic = t
            builder = topic.metaGetBuilder().withDesc().withSub()
        } else {
            // Existing topic.
            guard let t = tinode.getTopic(topicName: topicName) as? DefaultComTopic else { return .failed }
            topic = t
            builder = topic.metaGetBuilder()
        }

        guard !topic.attached else {
            // No need to fetch: topic is already subscribed and got data through normal channel.
            return .noData
        }
        if (topic.recv ?? 0) >= seq {
            return .noData
        }
        if let msg = try? topic.subscribe(set: nil, get: builder.withLaterData(limit: 10).withDel().build()).getResult(), (msg.ctrl?.code ?? 500) < 300 {
            if !keepConnection {
                // Data messages are sent asynchronously right after ctrl message.
                // Give them 1 second to arrive - so we reply back with {note recv}.
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                    if topic.attached {
                        topic.leave()
                    }
                }
            }
            return .newData
        }
        return .failed
    }


    // Update cached seq id of the last read message.
    public static func updateRead(using tinode: Tinode, for topicName: String, seq: Int) -> UIBackgroundFetchResult {
        // Don't need to handle 'read' notifications for an unknown topic.
        guard let topic = tinode.getTopic(topicName: topicName) as? DefaultComTopic else { return .failed }

        if topic.read ?? -1 < seq {
            topic.read = seq
            if let store = BaseDb.sharedInstance.sqlStore {
                _ = store.setRead(topic: topic, read: seq)
            }
        }
        return .noData
    }

    // Downloads an image.
    private static func downloadIcon(fromPath path: String, relativeTo baseUrl: URL, completion: @escaping ((UIImage?) -> Void)) {
        guard let url = URL(string: path, relativeTo: baseUrl) else {
            BaseDb.log.info("Invalid icon url: %@ %@", path, baseUrl.absoluteString)
            completion(nil)
            return
        }
        let task = URLSession.shared.dataTask(with: URLRequest(url: url)) { data, req, error in
            if let error = error {
                print(error.localizedDescription)
            }
            completion(data != nil ? UIImage(data: data!) : nil)
        }
        task.resume()
    }

    // Configures application branding from local configuration or remote fallback.
    public static func identifyAndConfigureBranding() {
        // Try local configuration first
        if let localConfig = loadLocalBrandingConfig() {
            BaseDb.log.info("Using local branding configuration")
            applyBrandingConfig(localConfig)
            return
        }

        // Fallback to remote configuration if local is unavailable
        BaseDb.log.info("Local branding config unavailable, falling back to remote")
        fetchRemoteBrandingConfig()
    }

    // Loads branding configuration from xcconfig via Bundle
    private static func loadLocalBrandingConfig() -> [String: Any]? {
        guard let serviceName = Bundle.main.object(forInfoDictionaryKey: "SERVICE_NAME") as? String,
              let tosUrl = Bundle.main.object(forInfoDictionaryKey: "TOS_URL") as? String,
              let privacyUrl = Bundle.main.object(forInfoDictionaryKey: "PRIVACY_URL") as? String,
              let apiHost = Bundle.main.object(forInfoDictionaryKey: "API_HOST") as? String,
              let appId = Bundle.main.object(forInfoDictionaryKey: "APP_ID") as? String,
              let useHttps = Bundle.main.object(forInfoDictionaryKey: "USE_HTTPS") as? String else {
            BaseDb.log.info("Local branding configuration keys missing from Bundle")
            return nil
        }

        let scheme = (useHttps.uppercased() == "YES") ? "https" : "http"
        let fullTosUrl = tosUrl.hasPrefix("http") ? tosUrl : "\(scheme)://\(tosUrl)"
        let fullPrivacyUrl = privacyUrl.hasPrefix("http") ? privacyUrl : "\(scheme)://\(privacyUrl)"
        let fullApiUrl = apiHost.hasPrefix("http") ? apiHost : "\(scheme)://\(apiHost)"

        return [
            "service_name": serviceName,
            "tos_url": fullTosUrl,
            "privacy_url": fullPrivacyUrl,
            "api_url": fullApiUrl,
            "id": appId
        ]
    }

    // Applies branding configuration from dictionary
    private static func applyBrandingConfig(_ config: [String: Any]) {
        if let tosUrl = config["tos_url"] as? String, !tosUrl.isEmpty {
            SharedUtils.tosUrl = tosUrl
        }

        if let serviceName = config["service_name"] as? String, !serviceName.isEmpty {
            SharedUtils.serviceName = serviceName
        }

        if let privacyUrl = config["privacy_url"] as? String, !privacyUrl.isEmpty {
            SharedUtils.privacyUrl = privacyUrl
        }

        if let apiUrl = config["api_url"] as? String, !apiUrl.isEmpty,
           let url = URL(string: apiUrl) {
            let useTLS = ["https", "wss"].contains(url.scheme) ? "true" : "false"
            if let host = url.host {
                setConnectionSettings(host, useTLS)
            }
        }

        if let appId = config["id"] as? String, !appId.isEmpty {
            SharedUtils.appId = appId
        }

        // Send notification that branding config is available
        NotificationCenter.default.post(
            name: Notification.Name(SharedUtils.kNotificationBrandingConfigAvailable),
            object: nil
        )

        BaseDb.log.info("Branding configuration applied successfully")
    }

    // Legacy remote branding configuration (fallback)
    private static func fetchRemoteBrandingConfig() {
        let device = UIDevice.current.userInterfaceIdiom == .phone ? "iphone" : UIDevice.current.userInterfaceIdiom == .pad ? "ipad" : ""
        let version = UIDevice.current.systemVersion
        let url = URL(string: "https://hosts.tinode.co/whoami?os=ios-\(version)&dev=\(device)")!
        let task = URLSession.shared.dataTask(with: URLRequest(url: url)) { data, response, error in
            guard let data = data, error == nil else {
                BaseDb.log.info("Branding config response error: %@", (error?.localizedDescription ?? "Failed to self-identify"))
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                if let code = responseJSON["code"] as? String {
                    SharedUtils.setUpBranding(withConfigurationCode: code)
                } else {
                    BaseDb.log.info("Branding config error: Missing configuration code in the response. Quitting.")
                }
            }
        }
        task.resume()
    }

    // Configures application branding and connection settings from remote source.
    public static func setUpBranding(withConfigurationCode configCode: String) {
        guard !configCode.isEmpty else {
            BaseDb.log.info("Branding configuration code may not be empty. Skipping branding config.")
            return
        }
        // Dummy url.
        // TODO: url should be based on the device fp (e.g. UIDevice.current.identifierForVendor).
        let url = URL(string: "https://hosts.tinode.co/id/\(configCode)")!

        let task = URLSession.shared.dataTask(with: URLRequest(url: url)) { data, response, error in
            guard let data = data, error == nil else {
                debugPrint(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                applyBrandingConfig(responseJSON)
                // Icons.
                if let assetsBase = responseJSON["assets_base"] as? String, let base = URL(string: assetsBase) {
                    if let smallIcon = responseJSON["icon_small"] as? String {
                        downloadIcon(fromPath: smallIcon, relativeTo: base) { img in
                            guard let img = img else { return }
                            SharedUtils.smallIcon = img
                            // Send notifications so all interested parties may use the new icon.
                            NotificationCenter.default.post(name: Notification.Name(SharedUtils.kNotificationBrandingSmallIconAvailable), object: img)
                        }
                    }
                    if let largeIcon = responseJSON["icon_large"] as? String {
                        downloadIcon(fromPath: largeIcon, relativeTo: base) { img in
                            guard let img = img else { return }
                            SharedUtils.largeIcon = img
                        }
                    }
                }
            }
        }
        task.resume()
    }

    // MARK: - Session Persistence Management

    private static let kLastSuccessfulConnection = "lastSuccessfulConnection"
    private static let kConnectionAttempts = "connectionAttempts"

    public static func recordSuccessfulConnection() {
        kAppDefaults.set(Date(), forKey: kLastSuccessfulConnection)
        kAppDefaults.set(0, forKey: kConnectionAttempts) // Reset attempts
        kAppDefaults.synchronize()
    }

    public static func recordFailedConnection() {
        let attempts = kAppDefaults.integer(forKey: kConnectionAttempts) + 1
        kAppDefaults.set(attempts, forKey: kConnectionAttempts)
        kAppDefaults.synchronize()
    }

    public static func shouldAttemptAutoReconnection() -> Bool {
        let attempts = kAppDefaults.integer(forKey: kConnectionAttempts)
        let lastConnection = kAppDefaults.object(forKey: kLastSuccessfulConnection) as? Date

        // If we had a successful connection in the last 24 hours and haven't failed too many times
        if let lastConnection = lastConnection,
           Date().timeIntervalSince(lastConnection) < 86400, // 24 hours
           attempts < 5 {
            return true
        }

        return false
    }

    // MARK: - Enhanced Token-Based Reconnection

    public static func isTokenValid() -> Bool {
        guard let token = getAuthToken(), !token.isEmpty else {
            return false
        }

        // If auto-logout is disabled, always consider token valid for reconnection attempt
        if !kEnableAutoLogout {
            return true
        }

        // Check token expiry only when auto-logout is enabled
        if let expiry = getAuthTokenExpiryDate() {
            return expiry > Date()
        }

        // If no expiry date, assume token is still valid for reconnection attempt
        return true
    }

    public static func attemptTokenBasedReconnection(using tinode: Tinode, completion: @escaping (Bool, String?) -> Void) {
        guard let userName = getSavedLoginUserName(), !userName.isEmpty,
              let token = getAuthToken(), !token.isEmpty else {
            completion(false, "No saved credentials available")
            return
        }

        BaseDb.log.info("Attempting token-based reconnection for user: %@", userName,token)

        tinode.setAutoLoginWithToken(token: token)

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let msg = try tinode.connectDefault(inBackground: false)?.getResult()
                if let ctrl = msg?.ctrl {
                    DispatchQueue.main.async {
                        switch ctrl.code {
                        case 0..<300:
                            let myUid = ctrl.getStringParam(for: "user")
                            BaseDb.log.info("Token-based reconnection successful for: %@", myUid ?? "unknown")

                            // Update token if server provided a new one
                            if let newAuthToken = tinode.authToken, newAuthToken != token {
                                saveAuthToken(for: userName, token: newAuthToken, expires: tinode.authTokenExpires)
                                BaseDb.log.info("Updated auth token after successful reconnection")
                            }

                            recordSuccessfulConnection()
                            completion(true, nil)

                        case 401, 403, 404:
                            BaseDb.log.error("Token-based reconnection failed - unauthorized (code: %d)", ctrl.code)
                            removeAuthToken()
                            completion(false, "AUTH_ERROR")

                        default:
                            BaseDb.log.error("Token-based reconnection failed - server error: %d", ctrl.code)
                            completion(false, "Connection failed with code: \(ctrl.code)")
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        BaseDb.log.error("Token-based reconnection failed - no response from server")
                        completion(false, "No response from server")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    BaseDb.log.error("Token-based reconnection failed - connection error: %@", error.localizedDescription)

                    // Check if it's an auth error
                    if let tinodeError = error as? TinodeError,
                       case .serverResponseError(let code, _, _) = tinodeError,
                       (code == 401 || code == 403 || code == 404) {
                        removeAuthToken()
                        completion(false, "AUTH_ERROR")
                    } else {
                        completion(false, error.localizedDescription)
                    }
                }
            }
        }
    }
}

extension Tinode {
    public static func getConnectionParams() -> (String, Bool) {
        let (hostName, useTLS) = SharedUtils.getConnectionSettings()
        return (hostName ?? SharedUtils.kDefaultHostName, useTLS ?? SharedUtils.kDefaultUseTLS)
    }

    @discardableResult
    public func connectDefault(inBackground bkg: Bool) throws -> PromisedReply<ServerMessage>? {
        let (hostName, useTLS) = Tinode.getConnectionParams()
        BaseDb.log.debug("Connecting to %@, secure %@", hostName, useTLS ? "YES" : "NO")
        return try connect(to: hostName, useTLS: useTLS, inBackground: bkg)
    }
}
