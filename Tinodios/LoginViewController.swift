//
//  LoginViewController.swift
//  Tinodios
//
//  Copyright © 2019 Tinode. All rights reserved.
//

import UIKit
import os
import SwiftKeychainWrapper
import TinodeSDK
import TinodiosDB

// MARK: - API Response Models

struct PreLoginDebugEntry: Codable {
    let message: String?
}

struct PreLoginResponse: Codable {
    let successes: [String]?
    let warnings: [String]?
    let errors: [String]?
    let debugs: [PreLoginDebugEntry]?
    let data: PreLoginData

    // Handles two server response shapes:
    // Format 1 (direct): { "success": true, "user": {...}, "token": {...}, "require_otp": false }
    // Format 2 (wrapped): { "successes": [], ..., "data": { "success": true, "user": {...}, ... } }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        successes = try container.decodeIfPresent([String].self, forKey: .successes)
        warnings  = try container.decodeIfPresent([String].self, forKey: .warnings)
        errors    = try container.decodeIfPresent([String].self, forKey: .errors)
        debugs    = try container.decodeIfPresent([PreLoginDebugEntry].self, forKey: .debugs)

        if let wrappedData = try container.decodeIfPresent(PreLoginData.self, forKey: .data) {
            data = wrappedData          // Format 2: data lives under "data" key
        } else {
            data = try PreLoginData(from: decoder)  // Format 1: data fields are at top level
        }
    }

    enum CodingKeys: String, CodingKey {
        case successes, warnings, errors, debugs, data
    }
}

struct TokenValues:Codable{
    let token:String?
    let expires_at:String?
}

struct PreLoginData: Codable {
    let success: Bool?
    let message: String?
    let requireOtp: Bool?
    let user: UserInfo?
    let token: TokenValues?

    enum CodingKeys: String, CodingKey {
        case success, message
        case requireOtp = "require_otp"
        case user, token
    }
}

struct OTPVerificationResponse: Codable {
    let success: Bool
    let message: String
}


struct UserInfo: Codable {
    let id: Int
    let sellerID: String?
    let userKey: String?
    let created: DateInfo?
    let modified: DateInfo?
    let deletedDate: String?
    let deleted: Bool?
    let firstname: String?
    let lastname: String?
    let email: String?
    let username: String?
    let nickname: String?
    let password: String?
    let active: Bool?
    let address1: String?
    let address2: String?
    let city: String?
    let state: String?
    let country: String?
    let zipcode: String?
    let title: String?
    let phone: String?
    let stationID: String?
    let apiKey: String?
    let roleID: Int?
    let additionalRoleIDs: String?
    let defaultDashboardID: String?
    let resetPasswordToken: String?
    let tokenCreatedAt: String?
    let passwordChanged: String?
    let systemUser: Bool?
    let lang: String?
    let baseSupplierID: String?
    let timezone: String?
    let image: String?
    let approved: Bool?
    let tinodeUserID: String?

    enum CodingKeys: String, CodingKey {
        case id
        case sellerID = "seller_id"
        case userKey = "user_key"
        case created, modified
        case deletedDate = "deleted_date"
        case deleted, firstname, lastname, email, username, nickname, password, active
        case address1, address2, city, state, country, zipcode, title, phone
        case stationID = "station_id"
        case apiKey = "api_key"
        case roleID = "role_id"
        case additionalRoleIDs = "additional_role_ids"
        case defaultDashboardID = "default_dashboard_id"
        case resetPasswordToken = "reset_password_token"
        case tokenCreatedAt = "token_created_at"
        case passwordChanged = "password_changed"
        case systemUser = "system_user"
        case lang
        case baseSupplierID = "base_supplier_id"
        case timezone, image, approved
        case tinodeUserID = "tinode_user_id"
    }
}

struct DateInfo: Codable {
    let date: String
    let timezoneType: Int
    let timezone: String

    enum CodingKeys: String, CodingKey {
        case date
        case timezoneType = "timezone_type"
        case timezone
    }
}

class LoginViewController: UIViewController {

    @IBOutlet weak var userNameTextEdit: UITextField!
    @IBOutlet weak var passwordTextEdit: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var logoView: UIImageView!
    @IBOutlet weak var serviceNameLabel: UILabel!
    @IBOutlet weak var poweredByStack: UIStackView!


    override func loadView() {
        super.loadView()
        // This is needed in order to adjust the height of the scroll view when the keyboard appears.
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIControl.keyboardWillShowNotification, object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIControl.keyboardWillHideNotification, object: self)
        // Make sure LoginVC gets notified when app logo icon becomes available.
        NotificationCenter.default.addObserver(self, selector: #selector(logoAvailable(_:)), name: Notification.Name(SharedUtils.kNotificationBrandingSmallIconAvailable), object: nil)
        // Get notified with the branding service name becomes available.
        NotificationCenter.default.addObserver(self, selector: #selector(brandingConfigAvailable(_:)), name: Notification.Name(SharedUtils.kNotificationBrandingConfigAvailable), object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Listen to text change events
        userNameTextEdit.addTarget(self, action: #selector(textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        passwordTextEdit.addTarget(self, action: #selector(textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        passwordTextEdit.showSecureEntrySwitch()

        UiUtils.dismissKeyboardForTaps(onView: self.view)

        if SharedUtils.appId != nil {
            // Branding is configured. Show "Powered by" view, hide configureConnectionButton.
            self.poweredByStack.isHidden = false

        } else {
            // Branding is not configured. Show "Configure connection" button, hide "Powered by" view.

            self.poweredByStack.isHidden = true
        }
        if let logo = SharedUtils.smallIcon {
            self.logoView.image = logo
        }
        if let serviceName = SharedUtils.serviceName {
            self.serviceNameLabel.text = serviceName
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: self)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidHideNotification, object: self)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(SharedUtils.kNotificationBrandingSmallIconAvailable), object: self)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(SharedUtils.kNotificationBrandingConfigAvailable), object: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Check current authentication state and redirect if already authenticated
        validateAuthenticationState()

        self.navigationController?.navigationBar.isHidden = true
        self.setInterfaceColors()
    }

    private func validateAuthenticationState() {
        // Check if we have a valid token and are already authenticated
        if let token = SharedUtils.getAuthToken(), !token.isEmpty {
            // Check if the Tinode connection is already authenticated
            let tinode = Cache.tinode
            if tinode.isConnectionAuthenticated {
                Cache.log.info("LoginVC - User already authenticated, redirecting to chat list")
                DispatchQueue.main.async {
                    UiUtils.routeToChatListVC()
                }
                return
            }

            // Check if token is expired (only if auto logout is enabled)
            if SharedUtils.kEnableAutoLogout {
                if let tokenExpiry = SharedUtils.getAuthTokenExpiryDate(), tokenExpiry < Date() {
                    Cache.log.info("LoginVC - Auth token expired, clearing and allowing re-login")
                    SharedUtils.removeAuthToken()
                    return
                }
            } else {
                Cache.log.info("LoginVC - Token expiry check disabled, using existing token")
            }

            // Token exists and not expired, attempt background re-authentication
            Cache.log.info("LoginVC - Valid token found, attempting background authentication")
            attemptBackgroundAuthentication(with: token)
        }
    }

    private func attemptBackgroundAuthentication(with token: String) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let tinode = Cache.tinode
            do {
                tinode.setAutoLoginWithToken(token: token)
                let success = try tinode.connectDefault(inBackground: true)?.getResult()

                if let ctrl = success?.ctrl, ctrl.code < 300 {
                    Cache.log.info("LoginVC - Background authentication successful")
                    DispatchQueue.main.async {
                        UiUtils.routeToChatListVC()
                    }
                } else {
                    Cache.log.info("LoginVC - Background authentication failed, token may be invalid")
                    DispatchQueue.main.async {
                        if SharedUtils.kEnableAutoLogout {
                            SharedUtils.removeAuthToken()
                            // Stay on login screen for fresh authentication
                        } else {
                            Cache.log.info("LoginVC - Background authentication failed, keeping token for retry")
                            // Stay on login screen but keep the token
                        }
                    }
                }
            } catch {
                Cache.log.error("LoginVC - Background authentication error: %@", error.localizedDescription)
                DispatchQueue.main.async {
                    // Don't clear token for network errors, user can try again
                    if let tinodeError = error as? TinodeError {
                        switch tinodeError {
                        case .invalidState(_):
                            if SharedUtils.kEnableAutoLogout {
                                // Clear invalid token
                                SharedUtils.removeAuthToken()
                            } else {
                                Cache.log.info("Invalid state error - keeping token for retry")
                            }
                        case .serverResponseError(let code, _, _):
                            if code >= 400 && SharedUtils.kEnableAutoLogout {
                                // Clear invalid token for client/server errors
                                SharedUtils.removeAuthToken()
                            } else {
                                Cache.log.info("Server error code %d - keeping token for retry", code)
                            }
                            // Keep token for 5xx server errors (temporary)
                        default:
                            // Keep token for network or temporary errors
                            break
                        }
                    }
                }
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.isHidden = false
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        guard UIApplication.shared.applicationState == .active else {
            return
        }
        self.setInterfaceColors()
    }

    private func setInterfaceColors() {
        if traitCollection.userInterfaceStyle == .dark {
            self.view.backgroundColor = .black
        } else {
            self.view.backgroundColor = .white
        }
    }

    @objc func keyboardWillShow(_ notification: Notification) {
        let userInfo: NSDictionary = notification.userInfo! as NSDictionary
        let keyboardScreenEndFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue

        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        let bottomInset = keyboardViewEndFrame.height - view.safeAreaInsets.bottom

        scrollView.contentInset.bottom = bottomInset
        scrollView.verticalScrollIndicatorInsets.bottom = bottomInset
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }

    @objc func textFieldDidChange(_ textField: UITextField) {
        textField.clearErrorSign()
    }

    // Logo image has just been downloaded. Use it.
    @objc func logoAvailable(_ notification: Notification) {
        guard let logo = notification.object as? UIImage else {
            Cache.log.error("LoginVC: logo available notification with an empty payload")
            return
        }
        DispatchQueue.main.async { self.logoView.image = logo }
    }

    // Service name has just become available. Use it.
    @objc func brandingConfigAvailable(_ notification: Notification) {
        DispatchQueue.main.async {
            if SharedUtils.appId != nil {

                self.poweredByStack.isHidden = false
            }
            if let serviceName = SharedUtils.serviceName {
                self.serviceNameLabel.text = serviceName
            }
        }
    }

    // MARK: - Validation Methods

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    private func isValidOTP(_ otp: String) -> Bool {
        let otpRegEx = "^[0-9]{6}$"  // Assuming 6-digit OTP
        let otpPred = NSPredicate(format:"SELF MATCHES %@", otpRegEx)
        return otpPred.evaluate(with: otp)
    }

    // MARK: - Authentication API Methods

    /// Returns the API base URL from configuration (Info.plist via .xcconfig)
    private var apiBaseURL: String {
         let apiUrl = "https://storm.saleswarp.com/bvfo-dev" 
        // let apiUrl = "https://bvfo-api.saleswarp.com" 

        let useHttps = Bundle.main.object(forInfoDictionaryKey: "USE_HTTPS") as? String
        let scheme = (useHttps?.uppercased() == "YES") ? "https" : "http"

        // Construct full URL if apiUrl doesn't already include scheme
        let fullUrl = apiUrl.hasPrefix("http") ? apiUrl : "\(scheme)://\(apiUrl)"
        return fullUrl
    }

    private func preLogin(username: String, password: String, completion: @escaping (Result<PreLoginResponse, Error>) -> Void) {
        guard let url = URL(string: "\(apiBaseURL)/FinancialUsers/preLogin") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0 // 30 second timeout

        let requestBody = ["User": ["username": username, "password": password]]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: -1, userInfo: nil)))
                return
            }

            // Debug: Log raw response for troubleshooting
            if let jsonString = String(data: data, encoding: .utf8) {
                Cache.log.info("PreLogin API Raw Response: %@", jsonString)
                Cache.log.info("PreLogin API Raw Response: %@",url as CVarArg )
            }

            // Log HTTP response status
            if let httpResponse = response as? HTTPURLResponse {
                Cache.log.info("PreLogin API Status Code: %d", httpResponse.statusCode)
            }

            do {
                let preLoginResponse = try JSONDecoder().decode(PreLoginResponse.self, from: data)
                Cache.log.info("PreLogin API Decoded Successfully")
                completion(.success(preLoginResponse))
            } catch {
                Cache.log.error("PreLogin API JSON Decode Error: %@", error.localizedDescription)

                // Log the exact decoding error details
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .dataCorrupted(let context):
                        Cache.log.error("Data corrupted: %@", context.debugDescription)
                    case .keyNotFound(let key, let context):
                        Cache.log.error("Key '%@' not found: %@", key.stringValue, context.debugDescription)
                    case .typeMismatch(let type, let context):
                        Cache.log.error("Type mismatch for type %@: %@", String(describing: type), context.debugDescription)
                    case .valueNotFound(let type, let context):
                        Cache.log.error("Value not found for type %@: %@", String(describing: type), context.debugDescription)
                    @unknown default:
                        Cache.log.error("Unknown decoding error: %@", error.localizedDescription)
                    }
                }

                // Create a more descriptive error for JSON parsing failures
                let detailedError = NSError(
                    domain: "PreLoginJSONError",
                    code: -2,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Failed to parse server response: \(error.localizedDescription)",
                        NSLocalizedFailureReasonErrorKey: "The server response format is invalid or missing required fields",
                        NSLocalizedRecoverySuggestionErrorKey: "Please try again or contact support if the problem persists"
                    ]
                )
                completion(.failure(detailedError))
            }
        }.resume()
    }

    private func verifyOTP(username: String, otp: String, completion: @escaping (Result<OTPVerificationResponse, Error>) -> Void) {
        guard let url = URL(string: "\(apiBaseURL)/FinancialUsers/verifyOtp") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0 // 30 second timeout

        let requestBody = ["username": username, "otp": otp]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                Cache.log.error("VerifyOTP Network Error: %@", error.localizedDescription)
                completion(.failure(error))
                return
            }

            guard let data = data else {
                Cache.log.error("VerifyOTP: No data received")
                completion(.failure(NSError(domain: "No data received", code: -1, userInfo: nil)))
                return
            }

            // Debug: Log raw response for troubleshooting
            if let jsonString = String(data: data, encoding: .utf8) {
                Cache.log.info("VerifyOTP API Raw Response: %@", jsonString)
            }

            // Log HTTP response status
            if let httpResponse = response as? HTTPURLResponse {
                Cache.log.info("VerifyOTP API Status Code: %d", httpResponse.statusCode)
            }

            do {
                let otpResponse = try JSONDecoder().decode(OTPVerificationResponse.self, from: data)
                Cache.log.info("VerifyOTP API Decoded Successfully")
                completion(.success(otpResponse))
            } catch {
                Cache.log.error("VerifyOTP API JSON Decode Error: %@", error.localizedDescription)

                // Log the exact decoding error details
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .dataCorrupted(let context):
                        Cache.log.error("Data corrupted: %@", context.debugDescription)
                    case .keyNotFound(let key, let context):
                        Cache.log.error("Key '%@' not found: %@", key.stringValue, context.debugDescription)
                    case .typeMismatch(let type, let context):
                        Cache.log.error("Type mismatch for type %@: %@", String(describing: type), context.debugDescription)
                    case .valueNotFound(let type, let context):
                        Cache.log.error("Value not found for type %@: %@", String(describing: type), context.debugDescription)
                    @unknown default:
                        Cache.log.error("Unknown decoding error: %@", error.localizedDescription)
                    }
                }

                // Create a more descriptive error for JSON parsing failures
                let detailedError = NSError(
                    domain: "VerifyOTPJSONError",
                    code: -2,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Failed to parse OTP verification response: \(error.localizedDescription)",
                        NSLocalizedFailureReasonErrorKey: "The server response format is invalid or missing required fields",
                        NSLocalizedRecoverySuggestionErrorKey: "Please try again or contact support if the problem persists"
                    ]
                )
                completion(.failure(detailedError))
            }
        }.resume()
    }

    private func login(username: String, password: String, completion: @escaping (Result<PreLoginResponse, Error>) -> Void) {
        guard let url = URL(string: "\(apiBaseURL)/FinancialUsers/login") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0 // 30 second timeout

        let requestBody = ["User": ["username": username, "password": password]]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                Cache.log.error("Login Network Error: %@", error.localizedDescription)
                completion(.failure(error))
                return
            }

            guard let data = data else {
                Cache.log.error("Login: No data received")
                completion(.failure(NSError(domain: "No data received", code: -1, userInfo: nil)))
                return
            }

            // Debug: Log raw response for troubleshooting
            if let jsonString = String(data: data, encoding: .utf8) {
                Cache.log.info("Login API Raw Response: %@", jsonString)
            }

            // Log HTTP response status
            if let httpResponse = response as? HTTPURLResponse {
                Cache.log.info("Login API Status Code: %d", httpResponse.statusCode)
            }

            do {
                let loginResponse = try JSONDecoder().decode(PreLoginResponse.self, from: data)
                Cache.log.info("Login API: Decoded response successfully")
                completion(.success(loginResponse))
            } catch {
                Cache.log.error("Login API: Failed to decode response: %@", error.localizedDescription)
                let detailedError = NSError(
                    domain: "LoginJSONError",
                    code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to parse login response: \(error.localizedDescription)"]
                )
                completion(.failure(detailedError))
            }
        }.resume()
    }

    private func loginWithSSO(token: String) {
        let tinode = Cache.tinode
        do {
            try tinode.connectDefault(inBackground: false)?
                .thenApply({ _ in
                    // Try token authentication first, fallback to SSO if needed
                    Cache.log.info("LoginVC - Attempting token authentication with: %@", String(token.prefix(10)) + "...")
                    return tinode.loginToken(token: token, creds: nil)
                })
                .then(
                    onSuccess: { [weak self] pkt in
                        Cache.log.info("LoginVC - Token login successful for %@", tinode.myUid!)
                        if let authToken = tinode.authToken {
                            if let username = SharedUtils.getSavedLoginUserName() {
                                SharedUtils.saveAuthToken(for: username, token: authToken, expires: tinode.authTokenExpires)
                            }
                        }
                        if let ctrl = pkt?.ctrl, ctrl.code >= 300, ctrl.text.contains("validate credentials") {
                            DispatchQueue.main.async { [weak self] in
                                UiUtils.routeToCredentialsVC(in: self?.navigationController,
                                                             verifying: ctrl.getStringArray(for: "cred")?.first)
                            }
                            return nil
                        }
                        UiUtils.routeToChatListVC()
                        return nil
                    }, onFailure: { [weak self] err in
                        Cache.log.error("LoginVC - Token login failed, trying SSO: %@", err.localizedDescription)

                        // Fallback to SSO authentication
                        guard let self = self else { return nil }
                        return tinode.loginSSO(token: token).then(
                            onSuccess: { pkt in
                                Cache.log.info("LoginVC - SSO login successful for %@", tinode.myUid!)
                                if let authToken = tinode.authToken {
                                    if let username = SharedUtils.getSavedLoginUserName() {
                                        SharedUtils.saveAuthToken(for: username, token: authToken, expires: tinode.authTokenExpires)
                                    }
                                }
                                UiUtils.routeToChatListVC()
                                return nil
                            },
                            onFailure: { ssoErr in
                                Cache.log.error("LoginVC - Both token and SSO login failed: %@", ssoErr.localizedDescription)
                                let errorClassification = self.classifyError(ssoErr)

                                DispatchQueue.main.async {
                                    UiUtils.showToast(message: errorClassification.message)
                                }

                                // Only invalidate cache for non-recoverable errors
                                if !errorClassification.isRecoverable {
                                    Cache.invalidate()
                                }
                                return nil
                            }
                        )
                    })
                    .thenFinally { [weak self] in
                        guard let loginVC = self else { return }
                        DispatchQueue.main.async {
                            UiUtils.toggleProgressOverlay(in: loginVC, visible: false)
                        }
                    }
        } catch {
            UiUtils.toggleProgressOverlay(in: self, visible: false)
            Cache.log.error("LoginVC - Failed to connect/login to Tinode: %@", error.localizedDescription)
            tinode.logout()
        }
    }

    @IBAction func loginClicked(_ sender: Any) {
        let userName = UiUtils.ensureDataInTextField(userNameTextEdit)
        let password = UiUtils.ensureDataInTextField(passwordTextEdit)

        guard !userName.isEmpty && !password.isEmpty else { return }

        // Validate email format
        guard isValidEmail(userName) else {
            UiUtils.showToast(message: "Please enter a valid email address")
            return
        }

        UiUtils.toggleProgressOverlay(in: self, visible: true, title: NSLocalizedString("Authenticating...", comment: "Authentication progress text"))

        // Step 1: Call preLogin API
        print("prelogin data \(userName) \(password)")
        preLogin(username: userName, password: password) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let preLoginResponse):
                    Cache.log.info("PreLogin response received: %@", String(describing: preLoginResponse))

                    // Validate required fields with nil-coalescing defaults
                    guard let success = preLoginResponse.data.success else {
                        Cache.log.error("PreLogin response missing 'success' field")
                        UiUtils.toggleProgressOverlay(in: self, visible: false)
                        UiUtils.showToast(message: "Invalid server response: missing success status")
                        return
                    }

                    if success {
                        let requireOtp = preLoginResponse.data.requireOtp ?? false

                        if requireOtp {
                            // Show success message first
                            UiUtils.showToast(message: "OTP sent to your whatsapp. Please check your inbox.",level:.info)
                            // OTP is required, show OTP verification
                            self.showOTPVerification(username: userName, password: password)
                        } else {
                            // No OTP required, check if token is provided in preLogin response
                            if let tokenValues = preLoginResponse.data.token,
                               let tokenData = tokenValues.token, !tokenData.isEmpty {
                                // Direct authentication with token from preLogin response
                                let expiryDate = tokenValues.expires_at.flatMap { Formatter.rfc3339.date(from: $0) }
                                self.performDirectSSO(username: userName, tokenData: tokenData, expires: expiryDate)
                            } else {
                                // Fallback to separate login call
                                self.performLogin(username: userName, password: password)
                            }
                        }
                    } else {
                        UiUtils.toggleProgressOverlay(in: self, visible: false)
                        let message = preLoginResponse.data.message ?? "Login failed. Please try again."
                        UiUtils.showToast(message: message)
                    }
                case .failure(let error):
                    UiUtils.toggleProgressOverlay(in: self, visible: false)
                    self.handlePreLoginError(error)
                }
            }
        }
    }

    // MARK: - PreLogin Error Handling

    private func handlePreLoginError(_ error: Error) {
        Cache.log.error("PreLogin failed with error: %@", error.localizedDescription)

        let errorInfo = classifyPreLoginError(error)

        // For recoverable errors, show retry option
        if errorInfo.isRecoverable {
            let alert = UIAlertController(
                title: "Connection Error",
                message: errorInfo.message,
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
                guard let self = self else { return }
                // Re-trigger login with existing credentials
                self.loginClicked(self)
            })

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            self.present(alert, animated: true)
        } else {
            // For non-recoverable errors, just show toast
            UiUtils.showToast(message: errorInfo.message)
        }
    }

    private func classifyPreLoginError(_ error: Error) -> ErrorClassification {
        // Check for URL errors (network-related)
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return ErrorClassification(
                    message: "No internet connection. Please check your network and try again.",
                    isRecoverable: true,
                    shouldClearToken: false
                )
            case .timedOut:
                return ErrorClassification(
                    message: "Request timed out. The server is taking too long to respond. Please try again.",
                    isRecoverable: true,
                    shouldClearToken: false
                )
            case .cannotConnectToHost, .cannotFindHost:
                return ErrorClassification(
                    message: "Cannot reach authentication server. Please check your connection and try again.",
                    isRecoverable: true,
                    shouldClearToken: false
                )
            case .secureConnectionFailed, .serverCertificateUntrusted:
                return ErrorClassification(
                    message: "Secure connection failed. Please check your network settings.",
                    isRecoverable: false,
                    shouldClearToken: false
                )
            default:
                return ErrorClassification(
                    message: "Network error occurred. Please check your connection and try again.",
                    isRecoverable: true,
                    shouldClearToken: false
                )
            }
        }

        // Check for NSError with specific domains
        if let nsError = error as NSError? {
            // JSON parsing errors from preLogin
            if nsError.domain == "PreLoginJSONError" {
                return ErrorClassification(
                    message: "Server response format is invalid. Please contact support if this persists.",
                    isRecoverable: false,
                    shouldClearToken: false
                )
            }

            // HTTP status code errors
            if nsError.domain == NSURLErrorDomain {
                if nsError.code >= 500 {
                    return ErrorClassification(
                        message: "Server is temporarily unavailable. Please try again in a few moments.",
                        isRecoverable: true,
                        shouldClearToken: false
                    )
                } else if nsError.code >= 400 {
                    return ErrorClassification(
                        message: "Authentication request was rejected. Please check your credentials.",
                        isRecoverable: false,
                        shouldClearToken: false
                    )
                }
            }
        }

        // Generic fallback with full error description
        return ErrorClassification(
            message: "Pre-login failed: \(error.localizedDescription)",
            isRecoverable: false,
            shouldClearToken: false
        )
    }

    private func classifyLoginError(_ error: Error) -> ErrorClassification {
        // Check for URL errors (network-related)
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return ErrorClassification(
                    message: "No internet connection during login. Please check your network and try again.",
                    isRecoverable: true,
                    shouldClearToken: false
                )
            case .timedOut:
                return ErrorClassification(
                    message: "Login request timed out. Please try again.",
                    isRecoverable: true,
                    shouldClearToken: false
                )
            case .cannotConnectToHost, .cannotFindHost:
                return ErrorClassification(
                    message: "Cannot reach server during login. Please check your connection and try again.",
                    isRecoverable: true,
                    shouldClearToken: false
                )
            case .secureConnectionFailed, .serverCertificateUntrusted:
                return ErrorClassification(
                    message: "Secure connection failed during login. Please check your network settings.",
                    isRecoverable: false,
                    shouldClearToken: false
                )
            default:
                return ErrorClassification(
                    message: "Network error occurred during login. Please try again.",
                    isRecoverable: true,
                    shouldClearToken: false
                )
            }
        }

        // Check for NSError with specific domains
        if let nsError = error as NSError? {
            // JSON parsing errors from login
            if nsError.domain == "LoginJSONError" {
                return ErrorClassification(
                    message: "Server response format error. Please try again or contact support.",
                    isRecoverable: true,
                    shouldClearToken: false
                )
            }

            // HTTP status code errors
            if nsError.domain == NSURLErrorDomain {
                if nsError.code >= 500 {
                    return ErrorClassification(
                        message: "Server temporarily unavailable during login. Please try again.",
                        isRecoverable: true,
                        shouldClearToken: false
                    )
                } else if nsError.code >= 400 {
                    return ErrorClassification(
                        message: "Login request was rejected. Please check your credentials.",
                        isRecoverable: false,
                        shouldClearToken: false
                    )
                }
            }
        }

        // Generic fallback
        return ErrorClassification(
            message: "Login failed: \(error.localizedDescription)",
            isRecoverable: false,
            shouldClearToken: false
        )
    }

    private func showOTPVerification(username: String, password: String) {
        // Dismiss the progress overlay before showing OTP dialog
        UiUtils.toggleProgressOverlay(in: self, visible: false)

        // Add a small delay to ensure smooth transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }

            let alert = UIAlertController(title: "OTP Verification",
                                        message: "An OTP has been sent to your whatsapp. Please enter it below to continue.",
                                        preferredStyle: .alert)

            alert.addTextField { textField in
                textField.placeholder = "Enter 6-digit OTP"
                textField.keyboardType = .numberPad
                textField.autocorrectionType = .no
                textField.autocapitalizationType = .none
            }

            let verifyAction = UIAlertAction(title: "Verify", style: .default) { [weak self] _ in
                guard let otpText = alert.textFields?.first?.text,
                      !otpText.isEmpty,
                      self?.isValidOTP(otpText) == true else {
                    UiUtils.showToast(message: "Please enter a valid 6-digit OTP")
                    return
                }

                // Show progress overlay while verifying OTP
                if let self = self {
                    UiUtils.toggleProgressOverlay(in: self, visible: true, title: NSLocalizedString("Verifying OTP...", comment: "OTP verification progress text"))
                }

                self?.verifyOTP(username: username, otp: otpText) { [weak self] result in
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        switch result {
                        case .success(let otpResponse):
                            if otpResponse.success {
                                // OTP verified successfully, proceed with login
                                self.performLogin(username: username, password: password)
                            } else {
                                UiUtils.toggleProgressOverlay(in: self, visible: false)
                                UiUtils.showToast(message: otpResponse.message)
                            }
                        case .failure(let error):
                            UiUtils.toggleProgressOverlay(in: self, visible: false)
                            UiUtils.showToast(message: "OTP verification failed: \(error.localizedDescription)")
                        }
                    }
                }
            }

            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
                guard let self = self else { return }
                UiUtils.toggleProgressOverlay(in: self, visible: false)
            }

            alert.addAction(verifyAction)
            alert.addAction(cancelAction)

            self.present(alert, animated: true)
        }
    }

    private func performLogin(username: String, password: String, retryCount: Int = 0) {
        login(username: username, password: password) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let loginResponse):
                    // Access nested data structure from PreLoginResponse
                    if let success = loginResponse.data.success, success,
                       let tokenValues = loginResponse.data.token,
                       let tokenData = tokenValues.token {
                        // Login successful, save user info with validation and proceed with SSO
                        let expiryDate = tokenValues.expires_at.flatMap { Formatter.rfc3339.date(from: $0) }
                        SharedUtils.saveAuthToken(for: username, token: tokenData, expires: expiryDate) { [weak self] success in
                            guard let self = self else { return }
                            if success {
                                Cache.log.info("LoginVC - Token saved successfully, proceeding with SSO login")
                                self.loginWithSSO(token: tokenData)
                            } else {
                                Cache.log.error("LoginVC - Failed to save auth token, aborting login")
                                UiUtils.toggleProgressOverlay(in: self, visible: false)
                                UiUtils.showToast(message: "Failed to save authentication data. Please try again.")
                            }
                        }
                    } else {
                        UiUtils.toggleProgressOverlay(in: self, visible: false)
                        let message = loginResponse.data.message ?? "Login failed"
                        UiUtils.showToast(message: message)
                    }
                case .failure(let error):
                    Cache.log.error("Login failed with error: %@", error.localizedDescription)

                    let errorInfo = self.classifyLoginError(error)

                    // For recoverable errors and within retry limit, show retry option
                    if errorInfo.isRecoverable && retryCount < 3 {
                        let alert = UIAlertController(
                            title: "Login Error",
                            message: errorInfo.message,
                            preferredStyle: .alert
                        )

                        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
                            guard let self = self else { return }
                            Cache.log.info("Retrying login (attempt %d)", retryCount + 1)
                            self.performLogin(username: username, password: password, retryCount: retryCount + 1)
                        })

                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                            UiUtils.toggleProgressOverlay(in: self, visible: false)
                        })

                        self.present(alert, animated: true)
                    } else {
                        // For non-recoverable errors or exceeded retry limit
                        UiUtils.toggleProgressOverlay(in: self, visible: false)

                        if retryCount >= 3 {
                            UiUtils.showToast(message: "Login failed after multiple attempts. Please try again later.")
                        } else {
                            UiUtils.showToast(message: errorInfo.message)
                        }
                    }
                }
            }
        }
    }

    private func performDirectSSO(username: String, tokenData: String, expires: Date?) {
        // Direct SSO authentication using token from preLogin response
        SharedUtils.saveAuthToken(for: username, token: tokenData, expires: expires) { [weak self] success in
            guard let self = self else { return }
            if success {
                Cache.log.info("LoginVC - Token from preLogin saved successfully, proceeding with SSO login")
                self.loginWithSSO(token: tokenData)
            } else {
                Cache.log.error("LoginVC - Failed to save auth token from preLogin, aborting login")
                UiUtils.toggleProgressOverlay(in: self, visible: false)
                UiUtils.showToast(message: "Failed to save authentication data. Please try again.")
            }
        }
    }

    // MARK: - Error Classification

    private struct ErrorClassification {
        let message: String
        let isRecoverable: Bool
        let shouldClearToken: Bool
    }

    private func classifyError(_ error: Error) -> ErrorClassification {
        Cache.log.info("LoginVC - Classifying error: %@", error.localizedDescription)

        if let tinodeError = error as? TinodeError {
            switch tinodeError {
            case .serverResponseError(let code, let text, _):
                return classifyServerError(code: code, text: text)
            case .invalidState(let reason):
                return ErrorClassification(
                    message: "Authentication state error: \(reason)",
                    isRecoverable: false,
                    shouldClearToken: true
                )
            case .notConnected(_):
                return ErrorClassification(
                    message: "Connection lost. Please check your network and try again.",
                    isRecoverable: true,
                    shouldClearToken: false
                )
            default:
                return ErrorClassification(
                    message: "Authentication failed: \(tinodeError.description)",
                    isRecoverable: false,
                    shouldClearToken: true
                )
            }
        }

        if let nsError = error as NSError? {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                return ErrorClassification(
                    message: "No network connection. Please check your internet and try again.",
                    isRecoverable: true,
                    shouldClearToken: false
                )
            case NSURLErrorCannotConnectToHost, NSURLErrorTimedOut:
                let (hostName, _) = Tinode.getConnectionParams()
                return ErrorClassification(
                    message: "Cannot connect to server at \(hostName). Please try again.",
                    isRecoverable: true,
                    shouldClearToken: false
                )
            case NSURLErrorServerCertificateUntrusted, NSURLErrorServerCertificateHasUnknownRoot:
                return ErrorClassification(
                    message: "Server certificate validation failed. Please check your connection.",
                    isRecoverable: false,
                    shouldClearToken: false
                )
            default:
                return ErrorClassification(
                    message: "Network error: \(error.localizedDescription)",
                    isRecoverable: true,
                    shouldClearToken: false
                )
            }
        }

        return ErrorClassification(
            message: "Login failed: \(error.localizedDescription)",
            isRecoverable: false,
            shouldClearToken: true
        )
    }

    private func classifyServerError(code: Int, text: String) -> ErrorClassification {
        switch code {
        case 400:
            return ErrorClassification(
                message: "Invalid request. Please check your credentials and try again.",
                isRecoverable: true,
                shouldClearToken: false
            )
        case 401:
            return ErrorClassification(
                message: "Authentication failed. Please check your credentials.",
                isRecoverable: true,
                shouldClearToken: true
            )
        case 403:
            return ErrorClassification(
                message: "Access forbidden. Your account may be suspended.",
                isRecoverable: false,
                shouldClearToken: true
            )
        case 404:
            return ErrorClassification(
                message: "User not found. Please check your credentials.",
                isRecoverable: true,
                shouldClearToken: true
            )
        case 429:
            return ErrorClassification(
                message: "Too many login attempts. Please wait and try again.",
                isRecoverable: true,
                shouldClearToken: false
            )
        case 500...599:
            return ErrorClassification(
                message: "Server error. Please try again later.",
                isRecoverable: true,
                shouldClearToken: false
            )
        default:
            return ErrorClassification(
                message: "Server returned error \(code): \(text)",
                isRecoverable: code < 500,
                shouldClearToken: code < 500
            )
        }
    }
}
