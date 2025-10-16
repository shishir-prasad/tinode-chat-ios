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

struct PreLoginResponse: Codable {
    let successes: [String]
    let warnings: [String]
    let errors: [String]
    let debugs: [String]
    let data: PreLoginData
}

struct PreLoginData: Codable {
    let success: Bool
    let message: String
    let requireOtp: Bool

    enum CodingKeys: String, CodingKey {
        case success, message
        case requireOtp = "require_otp"
    }
}

struct OTPVerificationResponse: Codable {
    let success: Bool
    let message: String
}

struct LoginResponse: Codable {
    let success: Bool
    let user: UserData?
    let token: String?
    let message: String?
}

struct UserData: Codable {
    let User: UserInfo
}

struct UserInfo: Codable {
    let id: Int
    let sellerID: String?
    let userKey: String?
    let created: DateInfo
    let modified: DateInfo
    let deletedDate: String?
    let deleted: Bool
    let firstname: String
    let lastname: String
    let email: String
    let username: String
    let nickname: String
    let password: String
    let active: Bool
    let address1: String
    let address2: String
    let city: String
    let state: String
    let country: String
    let zipcode: String
    let title: String?
    let phone: String
    let stationID: String?
    let apiKey: String
    let roleID: Int
    let additionalRoleIDs: String?
    let defaultDashboardID: String?
    let resetPasswordToken: String?
    let tokenCreatedAt: String?
    let passwordChanged: String?
    let systemUser: Bool
    let lang: String
    let baseSupplierID: String?
    let timezone: String
    let image: String?
    let approved: Bool
    let tinodeUserID: String

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
        self.navigationController?.navigationBar.isHidden = true
        self.setInterfaceColors()
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

    private func preLogin(username: String, password: String, completion: @escaping (Result<PreLoginResponse, Error>) -> Void) {
        guard let url = URL(string: "https://storm.saleswarp.com/bvfo-dev/FinancialUsers/preLogin") else {
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

            do {
                let preLoginResponse = try JSONDecoder().decode(PreLoginResponse.self, from: data)
                completion(.success(preLoginResponse))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    private func verifyOTP(username: String, otp: String, completion: @escaping (Result<OTPVerificationResponse, Error>) -> Void) {
        guard let url = URL(string: "https://storm.saleswarp.com/bvfo-dev/FinancialUsers/verifyOtp") else {
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
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: -1, userInfo: nil)))
                return
            }

            do {
                let otpResponse = try JSONDecoder().decode(OTPVerificationResponse.self, from: data)
                completion(.success(otpResponse))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    private func login(username: String, password: String, completion: @escaping (Result<LoginResponse, Error>) -> Void) {
        guard let url = URL(string: "https://storm.saleswarp.com/bvfo-dev/FinancialUsers/login") else {
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

            do {
                let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
                completion(.success(loginResponse))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    private func loginWithSSO(token: String) {
        let tinode = Cache.tinode
        do {
            try tinode.connectDefault(inBackground: false)?
                .thenApply({ _ in
                    return tinode.loginSSO(token: token)
                })
                .then(
                    onSuccess: { [weak self] pkt in
                        Cache.log.info("LoginVC - SSO login successful for %@", tinode.myUid!)
                        if let token = tinode.authToken {
                            tinode.setAutoLoginWithToken(token: token)
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
                    }, onFailure: { err in
                        Cache.log.error("LoginVC - SSO login failed: %@", err.localizedDescription)
                        var toastMsg: String
                        if let tinodeErr = err as? TinodeError {
                            toastMsg = "Tinode: \(tinodeErr.description)"
                        } else {
                            let (hostName, _) = Tinode.getConnectionParams()
                            toastMsg = String(format: NSLocalizedString("Couldn't connect to server at %@: %@", comment: "Error message"), hostName, err.localizedDescription)
                        }
                        DispatchQueue.main.async {
                            UiUtils.showToast(message: toastMsg)
                        }
                        Cache.invalidate()
                        return nil
                    }).thenFinally { [weak self] in
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
        preLogin(username: userName, password: password) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let preLoginResponse):
                    if preLoginResponse.data.success {
                        if preLoginResponse.data.requireOtp {
                            // Show success message first
                            UiUtils.showToast(message: "OTP sent to your whatsapp. Please check your inbox.")
                            // OTP is required, show OTP verification
                            self.showOTPVerification(username: userName, password: password)
                        } else {
                            // No OTP required, proceed with direct login
                            self.performLogin(username: userName, password: password)
                        }
                    } else {
                        UiUtils.toggleProgressOverlay(in: self, visible: false)
                        UiUtils.showToast(message: preLoginResponse.data.message)
                    }
                case .failure(let error):
                    UiUtils.toggleProgressOverlay(in: self, visible: false)
                    UiUtils.showToast(message: "Pre-login failed: \(error.localizedDescription)")
                }
            }
        }
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

    private func performLogin(username: String, password: String) {
        login(username: username, password: password) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let loginResponse):
                    if loginResponse.success, let token = loginResponse.token {
                        // Login successful, save user info and proceed with SSO
                        SharedUtils.saveAuthToken(for: username, token: token, expires: nil)
                        self.loginWithSSO(token: token)
                    } else {
                        UiUtils.toggleProgressOverlay(in: self, visible: false)
                        UiUtils.showToast(message: loginResponse.message ?? "Login failed")
                    }
                case .failure(let error):
                    UiUtils.toggleProgressOverlay(in: self, visible: false)
                    UiUtils.showToast(message: "Login failed: \(error.localizedDescription)")
                }
            }
        }
    }
}
