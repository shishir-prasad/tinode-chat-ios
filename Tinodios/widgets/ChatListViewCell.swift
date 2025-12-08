//
//  ChatListTableViewCell.swift
//
//  Copyright © 2019-2025 Tinode LLC. All rights reserved.
//

import UIKit
import TinodeSDK
import TinodiosDB

class ChatListViewCell: UITableViewCell {
    private static let kIconWidth: CGFloat = 18
    private static let kMessageStatusWidth: CGFloat = 14
    private static let kIconSeparator: CGFloat = 4

    @IBOutlet weak var icon: AvatarWithOnlineIndicator!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var subtitle: UILabel!
    @IBOutlet weak var unreadCount: UILabel!
    @IBOutlet weak var iconBlocked: UIImageView!
    @IBOutlet weak var iconMuted: UIImageView!
    @IBOutlet weak var iconBlockedWidth: NSLayoutConstraint!
    @IBOutlet weak var unreadCountWidth: NSLayoutConstraint!
    @IBOutlet weak var channelIndicator: UIImageView!
    @IBOutlet weak var channelIndicatorWidth: NSLayoutConstraint!
    @IBOutlet weak var iconMessageStatus: UIImageView!
    @IBOutlet weak var iconMessageStatusWidth: NSLayoutConstraint!
    @IBOutlet weak var badgeVerified: UIImageView!
    @IBOutlet weak var badgeVerifiedWidth: NSLayoutConstraint!
    @IBOutlet weak var badgeStaff: UIImageView!
    @IBOutlet weak var badgeStaffWidth: NSLayoutConstraint!
    @IBOutlet weak var badgeDanger: UIImageView!
    @IBOutlet weak var badgeDangerWidth: NSLayoutConstraint!

    // Pin indicator (programmatically created)
    private var pinIcon: UIImageView?
    private var pinIconLeadingConstraint: NSLayoutConstraint?

    override func awakeFromNib() {
        super.awakeFromNib()
        iconMuted.tintColor = UIColor.init(fromHexCode: 0xFFCCCCCC)
        iconBlocked.tintColor = iconMuted.tintColor
        setupPinIcon()
    }

    private func setupPinIcon() {
        if pinIcon == nil {
            pinIcon = UIImageView()
            pinIcon?.translatesAutoresizingMaskIntoConstraints = false
            pinIcon?.isHidden = true
            if #available(iOS 13.0, *) {
                pinIcon?.image = UIImage(systemName: "pin.fill")
            }
            pinIcon?.tintColor = .systemBlue
            pinIcon?.contentMode = .scaleAspectFit

            if let pinIcon = pinIcon {
                contentView.addSubview(pinIcon)

                // Initialize pin icon constraints (position will be updated dynamically)
                pinIconLeadingConstraint = pinIcon.leadingAnchor.constraint(equalTo: title.trailingAnchor, constant: 4)

                NSLayoutConstraint.activate([
                    pinIconLeadingConstraint!,
                    pinIcon.centerYAnchor.constraint(equalTo: title.centerYAnchor),
                    pinIcon.widthAnchor.constraint(equalToConstant: 12),
                    pinIcon.heightAnchor.constraint(equalToConstant: 12)
                ])
            }
        }
    }

    /// Updates pin icon position to appear after the last visible badge to prevent overlap
    private func updatePinIconPosition() {
        guard let pinIcon = pinIcon, let constraint = pinIconLeadingConstraint else { return }

        // Only reposition if pin icon is visible
        guard !pinIcon.isHidden else { return }

        // Find the rightmost visible badge to position pin icon after it
        var rightmostBadge: UIView = title
        var spacing: CGFloat = 4

        // Check badges in order from left to right (matches XIB layout sequence)
        if !channelIndicator.isHidden {
            rightmostBadge = channelIndicator
            spacing = 2 // Consistent with badge spacing in XIB
        }

        if !badgeVerified.isHidden {
            rightmostBadge = badgeVerified
            spacing = 2
        }

        if !badgeStaff.isHidden {
            rightmostBadge = badgeStaff
            spacing = 2
        }

        if !badgeDanger.isHidden {
            rightmostBadge = badgeDanger
            spacing = 2
        }

        // Update constraint to position pin after the rightmost visible element
        constraint.isActive = false
        pinIconLeadingConstraint = pinIcon.leadingAnchor.constraint(equalTo: rightmostBadge.trailingAnchor, constant: spacing)
        pinIconLeadingConstraint?.isActive = true

        // Ensure layout updates immediately for smooth animation
        setNeedsUpdateConstraints()
    }

    /// Helper method to get visible badge elements in layout order
    private func getVisibleBadges() -> [UIView] {
        var visibleBadges: [UIView] = []

        if !channelIndicator.isHidden { visibleBadges.append(channelIndicator) }
        if !badgeVerified.isHidden { visibleBadges.append(badgeVerified) }
        if !badgeStaff.isHidden { visibleBadges.append(badgeStaff) }
        if !badgeDanger.isHidden { visibleBadges.append(badgeDanger) }

        return visibleBadges
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        // Reset pin icon position for cell reuse
        if let constraint = pinIconLeadingConstraint {
            constraint.isActive = false
            pinIconLeadingConstraint = nil
        }

        // Re-setup the pin icon with default positioning
        if let pinIcon = pinIcon {
            pinIconLeadingConstraint = pinIcon.leadingAnchor.constraint(equalTo: title.trailingAnchor, constant: 4)
            pinIconLeadingConstraint?.isActive = true
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    private func setMessageStatusVisibility(hidden: Bool) {
        let width: CGFloat = hidden ? 0 : ChatListViewCell.kMessageStatusWidth
        iconMessageStatus.isHidden = hidden
        iconMessageStatusWidth.constant = width
    }

    public func fillFromTopic(topic: DefaultComTopic) {
        title.text = topic.isSlfType ? NSLocalizedString("Saved messages", comment: "Title of the slf topic") :
            topic.pub?.fn ?? NSLocalizedString("Unknown or unnamed", comment: "Topic title when it has no name")
        title.sizeToFit()
        if let msg = topic.latestMessage as? StoredMessage {
            // If we have a latestMessage and its up to date.
            subtitle.attributedText = msg.attributedPreview(fitIn: subtitle.frame.size)
            if msg.from == Cache.tinode.myUid {
                setMessageStatusVisibility(hidden: false)
                let (image, tint) = UiUtils.deliveryMarkerIcon(for: msg, in: topic)
                iconMessageStatus.image = image
                iconMessageStatus.tintColor = tint
            } else {
                setMessageStatusVisibility(hidden: true)
            }
        } else {
            subtitle.text = topic.isSlfType ?
                NSLocalizedString("Notes, messages, links, files saved for posterity", comment: "Explanation for Saved messages topic") :
                topic.comment
            setMessageStatusVisibility(hidden: true)
        }
        subtitle.sizeToFit()
        if topic.isChannel {
            channelIndicator.isHidden = false
            channelIndicatorWidth.constant = ChatListViewCell.kIconWidth
        } else {
            channelIndicator.isHidden = true
            channelIndicatorWidth.constant = .leastNonzeroMagnitude
        }

        if topic.isVerified {
            badgeVerified.isHidden = false
            badgeVerifiedWidth.constant = ChatListViewCell.kIconWidth
        } else {
            badgeVerified.isHidden = true
            badgeVerifiedWidth.constant = .leastNonzeroMagnitude
        }
        if topic.isStaffManaged {
            badgeStaff.isHidden = false
            badgeStaffWidth.constant = ChatListViewCell.kIconWidth
        } else {
            badgeStaff.isHidden = true
            badgeStaffWidth.constant = .leastNonzeroMagnitude
        }
        if topic.isDangerous {
            badgeDanger.isHidden = false
            badgeDangerWidth.constant = ChatListViewCell.kIconWidth
        } else {
            badgeDanger.isHidden = true
            badgeDangerWidth.constant = .leastNonzeroMagnitude
        }

        let unread = topic.unread
        if unread > 0 {
            unreadCount.text = unread > 9 ? "9+" : String(unread)
            unreadCount.isHidden = false
            unreadCountWidth.constant = ChatListViewCell.kIconWidth
        } else {
            unreadCount.isHidden = true
            unreadCountWidth.constant = .leastNonzeroMagnitude
        }

        iconBlocked.isHidden = !topic.isJoiner
        iconBlockedWidth.constant = topic.isJoiner ? .leastNonzeroMagnitude : ChatListViewCell.kIconWidth + ChatListViewCell.kIconSeparator * 2

        iconMuted.isHidden = topic.isSlfType || !topic.isMuted

        // Pin indicator - position after all badges to avoid overlap
        pinIcon?.isHidden = !topic.isPinned
        updatePinIconPosition()

        // Avatar image
        icon.set(pub: topic.pub, id: topic.name, online: (topic.isChannel || topic.isSlfType) ? nil : topic.online, deleted: topic.deleted)
    }
}
