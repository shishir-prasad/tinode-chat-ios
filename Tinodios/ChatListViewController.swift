//
//  ChatListViewController.swift
//  Tinodios
//
//  Copyright © 2019 Tinode. All rights reserved.
//

import UIKit
import TinodeSDK
import TinodiosDB

protocol ChatListDisplayLogic: AnyObject {
    func displayChats(_ topics: [DefaultComTopic], archivedTopics: [DefaultComTopic]?)
    func displayLoginView()
    func updateChat(_ name: String)
    func deleteChat(_ name: String)
}

class ChatListViewController: UITableViewController, ChatListDisplayLogic {

    private static let kFooterHeight: CGFloat = 30
    private static let kPoweredByFooterHeight: CGFloat = 24

    @IBOutlet var chatListTableView: UITableView!

    var interactor: ChatListBusinessLogic?
    var topics: [DefaultComTopic] = []
    var archivedTopics: [DefaultComTopic]?
    var numArchivedTopics: Int { return archivedTopics?.count ?? 0 }

    // Index of contacts: name => position in topics
    var rowIndex: [String: Int] = [:]
    var router: ChatListRoutingLogic?
    // Archived chats footer
    var archivedChatsFooter: UIView?
    // Powered by footer
    var poweredByFooter: UIView?

    private func setup() {
        let viewController = self
        let interactor = ChatListInteractor()
        let presenter = ChatListPresenter()
        let router = ChatListRouter()

        viewController.interactor = interactor
        viewController.router = router
        interactor.presenter = presenter
        interactor.router = router
        presenter.viewController = viewController
        router.viewController = viewController

        self.chatListTableView.register(UINib(nibName: "ChatListViewCell", bundle: nil), forCellReuseIdentifier: "ChatListViewCell")

        // Footer for Archived Chats link.
        archivedChatsFooter = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: ChatListViewController.kFooterHeight))
        archivedChatsFooter!.backgroundColor = tableView.backgroundColor
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: ChatListViewController.kFooterHeight))
        button.setTitle(NSLocalizedString("Archived Chats", comment: "View title"), for: .normal)
        button.setTitleColor(UIColor.secondaryLabel, for: .normal)
        button.titleLabel?.font = button.titleLabel?.font.withSize(15)
        button.addTarget(self, action: #selector(navigateToArchive), for: .touchUpInside)
        archivedChatsFooter!.addSubview(button)

        // Create powered by footer
        createPoweredByFooter()

        // Set up combined footer view
        setupCombinedFooter()
        // Customize the title if needed.
        if let serviceName = SharedUtils.serviceName {
            self.title = serviceName
        }
    }

    private func createPoweredByFooter() {
        // Only show powered by footer if branding is configured
        guard SharedUtils.appId != nil else { return }

        poweredByFooter = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: ChatListViewController.kPoweredByFooterHeight))
        poweredByFooter!.backgroundColor = tableView.backgroundColor

        // Create stack view similar to login screen
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false

        // Create logo image view
        let logoImageView = UIImageView()
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.clipsToBounds = true
        logoImageView.translatesAutoresizingMaskIntoConstraints = false

        // Use the same logo as login screen
        if let logo = UIImage(named: "logo-ios") {
            logoImageView.image = logo
        } else if let logo = SharedUtils.smallIcon {
            logoImageView.image = logo
        }

        // Create label
        let label = UILabel()
        label.text = "Powered By CloudQix"
        label.textColor = UIColor.secondaryLabel
        label.font = UIFont.systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false

        // Add subviews to stack
        stackView.addArrangedSubview(logoImageView)
        stackView.addArrangedSubview(label)

        poweredByFooter!.addSubview(stackView)

        // Set constraints
        NSLayoutConstraint.activate([
            // Logo size constraints
            logoImageView.widthAnchor.constraint(equalToConstant: 24),
            logoImageView.heightAnchor.constraint(equalToConstant: 24),

            // Stack view constraints
            stackView.centerXAnchor.constraint(equalTo: poweredByFooter!.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: poweredByFooter!.centerYAnchor),
            stackView.heightAnchor.constraint(equalToConstant: ChatListViewController.kPoweredByFooterHeight)
        ])
    }

    private func setupCombinedFooter() {
        let shouldShowPoweredBy = SharedUtils.appId != nil
        let shouldShowArchived = numArchivedTopics > 0

        if shouldShowPoweredBy && shouldShowArchived {
            // Create combined footer with both powered by and archived chats
            let totalHeight = ChatListViewController.kPoweredByFooterHeight + ChatListViewController.kFooterHeight + 10 // 10pt spacing
            let combinedFooter = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: totalHeight))
            combinedFooter.backgroundColor = tableView.backgroundColor

            // Add powered by footer at the top
            if let poweredBy = poweredByFooter {
                poweredBy.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: ChatListViewController.kPoweredByFooterHeight)
                combinedFooter.addSubview(poweredBy)
            }

            // Add archived footer below with spacing
            if let archived = archivedChatsFooter {
                archived.frame = CGRect(x: 0, y: ChatListViewController.kPoweredByFooterHeight + 10, width: tableView.frame.width, height: ChatListViewController.kFooterHeight)
                combinedFooter.addSubview(archived)
            }

            tableView.tableFooterView = combinedFooter
        } else if shouldShowPoweredBy {
            // Show only powered by footer
            tableView.tableFooterView = poweredByFooter
        } else if shouldShowArchived {
            // Show only archived footer
            tableView.tableFooterView = archivedChatsFooter
        } else {
            // No footer
            tableView.tableFooterView = nil
        }
    }

    private func toggleFooter(visible: Bool) {
        if visible {
            let count = numArchivedTopics > 9 ? "9+" : String(numArchivedTopics)
            if let button = archivedChatsFooter?.subviews.first as? UIButton {
                button.setTitle(String(format: NSLocalizedString("Archived Chats (%@)", comment: "Button to open chat archive"), count), for: .normal)
            }
        }

        // Recreate the combined footer to reflect the archived chats visibility
        setupCombinedFooter()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setup()

        NotificationCenter.default.addObserver(
            self, selector: #selector(self.appGoingInactive),
            name: UIApplication.willResignActiveNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(self.appBecameActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil)
    }
    deinit {
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.willResignActiveNotification,
            object: nil)
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.didBecomeActiveNotification,
            object: nil)
    }
    @objc
    func appBecameActive() {
        self.interactor?.setup()
        self.interactor?.attachToMeTopic()
        // Reload topics after the app became active.
        self.interactor?.loadAndPresentTopics()
    }
    @objc
    func appGoingInactive() {
        self.interactor?.cleanup()
        self.interactor?.leaveMeTopic()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.interactor?.setup()
        self.interactor?.attachToMeTopic()
        self.interactor?.loadAndPresentTopics()
    }

    // Continue listening on meTopic even when the VC isn't visible.
    // TODO: remote this.
    // override func viewDidDisappear(_ animated: Bool) {
    //     self.interactor?.cleanup()
    // }

    func displayLoginView() {
        if SharedUtils.kEnableAutoLogout {
            UiUtils.logoutAndRouteToLoginVC()
        } else {
            // Show authentication error with options instead of forced logout
            UiUtils.showAuthenticationErrorWithOptions()
        }
    }

    func displayChats(_ topics: [DefaultComTopic], archivedTopics: [DefaultComTopic]?) {
        assert(Thread.isMainThread)
        self.topics = topics
        self.archivedTopics = archivedTopics
        self.rowIndex = Dictionary(uniqueKeysWithValues: topics.enumerated().map { (index, topic) in (topic.name, index) })
        self.tableView!.reloadData()
        self.toggleFooter(visible: self.numArchivedTopics > 0)
    }

    func updateChat(_ name: String) {
        assert(Thread.isMainThread)
        guard let position = rowIndex[name] else { return }
        self.tableView!.reloadRows(at: [IndexPath(item: position, section: 0)], with: .none)
        self.toggleFooter(visible: self.numArchivedTopics > 0)
    }

    func deleteChat(_ name: String) {
        assert(Thread.isMainThread)
        guard let position = rowIndex[name] else { return }
        self.topics.remove(at: position)
        self.tableView!.deleteRows(at: [IndexPath(item: position, section: 0)], with: .fade)
        self.toggleFooter(visible: self.numArchivedTopics > 0)
    }

    @objc private func navigateToArchive() {
        self.performSegue(withIdentifier: "Chats2Archive", sender: nil)
    }
}

// UITableViewController
extension ChatListViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Chats2Messages", let topicName = sender as? String {
            router?.routeToChat(withName: topicName, for: segue)
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        toggleNoChatsNote(on: topics.isEmpty)
        return topics.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatListViewCell") as! ChatListViewCell
        let topic = self.topics[indexPath.row]
        cell.fillFromTopic(topic: topic)
        return cell
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let topic = self.topics[indexPath.row]
        var actions: [UIContextualAction] = []

        // Delete item at indexPath
        let delete = UIContextualAction(style: .destructive, title: NSLocalizedString("Delete", comment: "Swipe action"), handler: { _,_,_ in
            self.interactor?.deleteTopic(topic.name)
        })
        actions.append(delete)

        // Archive action
        let archive = UIContextualAction(style: .normal, title: NSLocalizedString("Archive", comment: "Swipe action"), handler: { _,_,_ in
            self.interactor?.changeArchivedStatus(
                forTopic: topic.name, archived: !topic.isArchived)
        })
        actions.append(archive)

        // Pin/Unpin action
        let pinTitle = topic.isPinned ? NSLocalizedString("Unpin", comment: "Swipe action") : NSLocalizedString("Pin", comment: "Swipe action")
        let pin = UIContextualAction(style: .normal, title: pinTitle, handler: { _,_,_ in
            self.togglePinStatus(for: topic)
        })
        pin.backgroundColor = topic.isPinned ? .systemOrange : .systemBlue
        if #available(iOS 13.0, *) {
            pin.image = UIImage(systemName: topic.isPinned ? "pin.slash" : "pin")
        }
        actions.append(pin)

        return UISwipeActionsConfiguration(actions: actions)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.performSegue(withIdentifier: "Chats2Messages", sender: self.topics[indexPath.row].name)
    }

    private func togglePinStatus(for topic: DefaultComTopic) {
        let previouslyPinned = topic.isPinned
        topic.updatePinned(pinned: !previouslyPinned)?.then(
            onSuccess: { [weak self] _ in
                DispatchQueue.main.async {
                    // Refresh the chat list to show the new pin status and order
                    self?.interactor?.loadAndPresentTopics()
                }
                return nil
            },
            onFailure: { [weak self] error in
                DispatchQueue.main.async {
                    let alertMessage = previouslyPinned ?
                        NSLocalizedString("Failed to unpin chat", comment: "Error message") :
                        NSLocalizedString("Failed to pin chat", comment: "Error message")
                    self?.showErrorAlert(message: alertMessage)
                }
                return nil
            }
        )
    }

    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: NSLocalizedString("Error", comment: "Alert title"),
                                    message: message,
                                    preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Button"), style: .default))
        present(alert, animated: true)
    }
}

extension ChatListViewController {

    /// Show notification that the chat list is empty
    public func toggleNoChatsNote(on show: Bool) {
        if show {
            let rect = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
            let messageLabel = UILabel(frame: rect)
            messageLabel.text = NSLocalizedString("You have no chats\n\n¯\\_(ツ)_/¯", comment: "Placeholder when no chats found")
            messageLabel.textColor = .secondaryLabel
            messageLabel.numberOfLines = 0
            messageLabel.textAlignment = .center
            messageLabel.font = UIFont.preferredFont(forTextStyle: .body)
            messageLabel.sizeToFit()

            tableView.backgroundView = messageLabel
        } else {
            tableView.backgroundView = nil
        }
    }
}
