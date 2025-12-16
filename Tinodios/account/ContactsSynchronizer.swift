//
//  ContactsSynchronizer.swift
//  Tinodios
//
//  Copyright © 2019-2025 Tinode. All rights reserved.
//

import Foundation
import Contacts
import TinodeSDK
import TinodiosDB

class ContactsSynchronizer {
    private class ContactHolder2 {
        var displayName: String?
        var imageThumbnail: Data?
        var phones: [String]?
        var emails: [String]?

        func toString() -> String {
            var vals = [String]()
            if let phones = self.phones {
                vals += phones
            }
            if let emails = self.emails {
                vals += emails
            }
            return vals.joined(separator: ",")
        }
    }
    public static let `default` = ContactsSynchronizer()
    private let store = CNContactStore()
    private let queue = DispatchQueue(label: "co.tinode.sync")
    public var authStatus: CNAuthorizationStatus = .notDetermined {
        didSet {
            if self.authStatus == .authorized {
                permissionsChangedCallback?(self.authStatus)
                queue.async {
                    self.synchronizeInternal()
                }
            }
        }
    }
    private static let kTinodeServerSyncMarker = "tinodeServerSyncMarker"
    private var serverSyncMarker: Date? {
        get {
            return SharedUtils.kAppDefaults.object(
                forKey: ContactsSynchronizer.kTinodeServerSyncMarker) as? Date
        }
        set {
            if let v = newValue {
                SharedUtils.kAppDefaults.set(
                    v, forKey: ContactsSynchronizer.kTinodeServerSyncMarker)
            }
        }
    }
    public var permissionsChangedCallback: ((CNAuthorizationStatus) -> Void)?

    public init() {
        // Watch contact book changes.
        NotificationCenter.default.addObserver(
                self, selector: #selector(contactStoreDidChange), name: .CNContactStoreDidChange, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(self.appBecameActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil)
    }

    @objc func contactStoreDidChange(notification: NSNotification) {
        Cache.log.info("Contact change: notification %@", notification)
        self.run()
    }

    @objc
    func appBecameActive() {
        if self.authStatus == .authorized {
            self.run()
        } else {
            Cache.log.debug("Can't perform contact sync: unauthorized")
        }
    }

    private func fetchContacts() -> [ContactHolder2]? {
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactImageDataAvailableKey as CNKeyDescriptor,
            CNContactThumbnailImageDataKey as CNKeyDescriptor
        ]
        var contacts = [CNContact]()
        let request = CNContactFetchRequest(keysToFetch: keysToFetch)
        do {
            try self.store.enumerateContacts(with: request) {
                (contact, _) -> Void in
                contacts.append(contact)
            }
        } catch let error {
            Cache.log.error("ContactsSynchronizer - system contact fetch error: %@", error.localizedDescription)
        }

        return contacts.map {
            let systemContact = $0
            let contactHolder = ContactHolder2()
            contactHolder.displayName = "\(systemContact.givenName) \(systemContact.familyName)"
            contactHolder.imageThumbnail = systemContact.imageDataAvailable ? systemContact.thumbnailImageData : nil
            contactHolder.emails = systemContact.emailAddresses.map { String($0.value) }
            contactHolder.phones = systemContact.phoneNumbers.map { $0.value.naiveE164 }
            return contactHolder
        }
    }
    func run() {
        // Contact synchronization disabled - no longer requesting contact permissions
        Cache.log.info("ContactsSynchronizer - synchronization disabled, skipping run")
        return
    }
    private func contactsToQueryString(contacts: [ContactHolder2]) -> String {
        return contacts.map { $0.toString() }.joined(separator: ",")
    }
    private func synchronizeInternal() {
        // Contact synchronization disabled - no longer syncing with server
        Cache.log.info("ContactsSynchronizer - synchronization disabled, skipping sync")
        return
    }
}

extension CNPhoneNumber {
    // Hack: simply filters out all non-digit characters.
    var naiveE164: String {
        return self.value(forKey: "unformattedInternationalStringValue") as? String ?? ""
    }
}
