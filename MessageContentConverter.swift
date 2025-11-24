//
//  MessageContentConverter.swift
//  Tinodios
//
//  Created for converting HTML and Markdown content to NSAttributedString
//

import Foundation
import UIKit

/// Utility class for detecting and converting different message content formats
class MessageContentConverter {

    /// Detect if a string contains HTML tags
    static func isHTML(_ text: String) -> Bool {
        // More comprehensive HTML detection
        // Check for common HTML tags and entities
        let htmlPatterns = [
            "<[a-zA-Z][^>]*>.*?</[a-zA-Z]+>",  // Opening and closing tags
            "<[a-zA-Z][^>]*/?>",                // Self-closing or single tags
            "&[a-zA-Z]+;",                      // HTML entities like &nbsp; &lt; &gt;
            "&#[0-9]+;",                        // Numeric entities
        ]

        for pattern in htmlPatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
                continue
            }
            let range = NSRange(location: 0, length: text.utf16.count)
            if regex.firstMatch(in: text, options: [], range: range) != nil {
                return true
            }
        }
        return false
    }

    /// Detect if a string contains Markdown formatting
    static func isMarkdown(_ text: String) -> Bool {
        // More comprehensive markdown pattern detection
        let patterns = [
            "\\*\\*[^*\\n]+\\*\\*",              // **bold**
            "__[^_\\n]+__",                       // __bold__
            "(?<!\\*)\\*[^*\\n]+\\*(?!\\*)",     // *italic* (not part of **)
            "(?<!_)_[^_\\n]+_(?!_)",             // _italic_ (not part of __)
            "~~[^~\\n]+~~",                       // ~~strikethrough~~
            "`[^`\\n]+`",                         // `code`
            "\\[.+?\\]\\(.+?\\)",                 // [link](url)
            "^#{1,6}\\s.+$",                      // # headers
            "^\\s*[-*+]\\s",                      // - list items
            "^\\s*\\d+\\.\\s",                    // 1. numbered lists
            "^>\\s",                              // > blockquote
            "^```",                               // ``` code blocks
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) {
                let range = NSRange(location: 0, length: text.utf16.count)
                if regex.firstMatch(in: text, options: [], range: range) != nil {
                    return true
                }
            }
        }
        return false
    }

    /// Convert Markdown to NSAttributedString using native iOS 15+ support
    @available(iOS 15.0, *)
    static func nativeMarkdownToAttributedString(_ markdown: String, defaultAttributes: [NSAttributedString.Key: Any]) -> NSAttributedString? {
        do {
            // Try to use native Markdown parser (iOS 15+)
            var attributedString = try AttributedString(markdown: markdown, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))

            // Apply default attributes
            if let font = defaultAttributes[.font] as? UIFont {
                attributedString.font = font
            }
            if let color = defaultAttributes[.foregroundColor] as? UIColor {
                attributedString.foregroundColor = color
            }

            return NSAttributedString(attributedString)
        } catch {
            print("Native markdown parsing failed: \(error)")
            return nil
        }
    }

    /// Convert HTML string to NSAttributedString
    static func htmlToAttributedString(_ html: String, defaultAttributes: [NSAttributedString.Key: Any]) -> NSAttributedString? {
        guard let data = html.data(using: .utf8) else { return nil }

        // Get the default font from attributes
        let defaultFont = defaultAttributes[.font] as? UIFont ?? UIFont.preferredFont(forTextStyle: .body)
        let defaultColor = defaultAttributes[.foregroundColor] as? UIColor ?? .label

        // Create HTML with inline CSS to match the default font
        let fontFamily = defaultFont.familyName
        let fontSize = defaultFont.pointSize
        let colorHex = defaultColor.toHexString()

        let styledHTML = """
        <html>
        <head>
        <style>
        body {
            font-family: '\(fontFamily)', -apple-system, system-ui;
            font-size: \(fontSize)px;
            color: \(colorHex);
            margin: 0;
            padding: 0;
        }
        p { margin: 0; padding: 0; }
        </style>
        </head>
        <body>\(html)</body>
        </html>
        """

        guard let styledData = styledHTML.data(using: .utf8) else { return nil }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        do {
            let attributedString = try NSMutableAttributedString(
                data: styledData,
                options: options,
                documentAttributes: nil
            )

            // Apply default font and color to ensure consistency
            let range = NSRange(location: 0, length: attributedString.length)
            attributedString.addAttributes(defaultAttributes, range: range)

            return attributedString
        } catch {
            print("Error converting HTML to attributed string: \(error)")
            return nil
        }
    }

    /// Convert Markdown string to NSAttributedString with fallback for older iOS versions
    static func markdownToAttributedString(_ markdown: String, defaultAttributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        // Try native iOS 15+ Markdown parser first
        if #available(iOS 15.0, *) {
            if let nativeResult = nativeMarkdownToAttributedString(markdown, defaultAttributes: defaultAttributes) {
                return nativeResult
            }
        }

        // Fallback to manual parsing
        return manualMarkdownToAttributedString(markdown, defaultAttributes: defaultAttributes)
    }

    /// Manual Markdown parsing fallback for older iOS or when native parsing fails
    private static func manualMarkdownToAttributedString(_ markdown: String, defaultAttributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        let mutableString = NSMutableAttributedString(string: markdown, attributes: defaultAttributes)
        let fullRange = NSRange(location: 0, length: mutableString.length)

        // Get the default font
        let defaultFont = defaultAttributes[.font] as? UIFont ?? UIFont.preferredFont(forTextStyle: .body)

        // Apply markdown patterns
        let patterns: [(pattern: String, apply: (NSMutableAttributedString, NSTextCheckingResult, UIFont) -> Void)] = [
            // Bold with **text**
            ("\\*\\*([^*]+)\\*\\*", { string, result, font in
                if result.numberOfRanges >= 2 {
                    let matchRange = result.range(at: 0)
                    let contentRange = result.range(at: 1)
                    let boldFont = font.withTraits(traits: .traitBold)

                    // Get the content text
                    let content = (string.string as NSString).substring(with: contentRange)

                    // Replace the markdown with styled text
                    string.replaceCharacters(in: matchRange, with: content)
                    let newRange = NSRange(location: matchRange.location, length: content.count)
                    string.addAttribute(.font, value: boldFont, range: newRange)
                }
            }),

            // Bold with __text__
            ("__([^_]+)__", { string, result, font in
                if result.numberOfRanges >= 2 {
                    let matchRange = result.range(at: 0)
                    let contentRange = result.range(at: 1)
                    let boldFont = font.withTraits(traits: .traitBold)

                    let content = (string.string as NSString).substring(with: contentRange)
                    string.replaceCharacters(in: matchRange, with: content)
                    let newRange = NSRange(location: matchRange.location, length: content.count)
                    string.addAttribute(.font, value: boldFont, range: newRange)
                }
            }),

            // Italic with *text* (but not **)
            ("(?<!\\*)\\*([^*]+)\\*(?!\\*)", { string, result, font in
                if result.numberOfRanges >= 2 {
                    let matchRange = result.range(at: 0)
                    let contentRange = result.range(at: 1)
                    let italicFont = font.withTraits(traits: .traitItalic)

                    let content = (string.string as NSString).substring(with: contentRange)
                    string.replaceCharacters(in: matchRange, with: content)
                    let newRange = NSRange(location: matchRange.location, length: content.count)
                    string.addAttribute(.font, value: italicFont, range: newRange)
                }
            }),

            // Italic with _text_
            ("(?<!_)_([^_]+)_(?!_)", { string, result, font in
                if result.numberOfRanges >= 2 {
                    let matchRange = result.range(at: 0)
                    let contentRange = result.range(at: 1)
                    let italicFont = font.withTraits(traits: .traitItalic)

                    let content = (string.string as NSString).substring(with: contentRange)
                    string.replaceCharacters(in: matchRange, with: content)
                    let newRange = NSRange(location: matchRange.location, length: content.count)
                    string.addAttribute(.font, value: italicFont, range: newRange)
                }
            }),

            // Strikethrough with ~~text~~
            ("~~([^~]+)~~", { string, result, font in
                if result.numberOfRanges >= 2 {
                    let matchRange = result.range(at: 0)
                    let contentRange = result.range(at: 1)

                    let content = (string.string as NSString).substring(with: contentRange)
                    string.replaceCharacters(in: matchRange, with: content)
                    let newRange = NSRange(location: matchRange.location, length: content.count)
                    string.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: newRange)
                }
            }),

            // Code with `text`
            ("`([^`]+)`", { string, result, font in
                if result.numberOfRanges >= 2 {
                    let matchRange = result.range(at: 0)
                    let contentRange = result.range(at: 1)
                    let monoFont = UIFont(name: "Courier", size: font.pointSize) ?? font

                    let content = (string.string as NSString).substring(with: contentRange)
                    string.replaceCharacters(in: matchRange, with: content)
                    let newRange = NSRange(location: matchRange.location, length: content.count)
                    string.addAttribute(.font, value: monoFont, range: newRange)
                }
            })
        ]

        // Process patterns in reverse order to handle nested formatting correctly
        // We need to iterate multiple times due to replacements changing ranges
        for (patternString, applyStyle) in patterns {
            guard let regex = try? NSRegularExpression(pattern: patternString, options: []) else { continue }

            // Keep applying until no more matches (since we're replacing text)
            var searchRange = NSRange(location: 0, length: mutableString.length)
            while let match = regex.firstMatch(in: mutableString.string, options: [], range: searchRange) {
                applyStyle(mutableString, match, defaultFont)
                // After replacement, search from the same position
                searchRange = NSRange(location: match.range.location, length: mutableString.length - match.range.location)
            }
        }

        return mutableString
    }
}

// MARK: - UIColor Extension
extension UIColor {
    func toHexString() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        getRed(&r, green: &g, blue: &b, alpha: &a)

        let rgb: Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        return String(format: "#%06x", rgb)
    }
}
