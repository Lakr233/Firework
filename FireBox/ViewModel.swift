//
//  ViewModel.swift
//  FireBox
//
//  Created for FireBox on 2024/2/9.
//

import Foundation
import Observation

struct FireworkMessage: Codable, Identifiable {
    let id: UUID
    let text: String

    init(id: UUID = UUID(), text: String) {
        self.id = id
        self.text = text
    }
}

@MainActor
@Observable
final class ViewModel {
    static let shared = ViewModel()
    static let maximumMessageLength = 16

    private static let messagesKey = "fireworkMessages"
    private static let selectedMessageKey = "selectedFireworkMessageID"
    private static let defaultMessageKeys = [
        "🎆 Happy New Year",
        "🧨 Best Wishes",
        "✨ Peace and Joy",
        "🎉 Happy Birthday",
        "💖 Love You Every Day",
        "🌟 May Dreams Come True",
    ]

    private static var localizedDefaultTexts: [String] {
        defaultMessageKeys.map { String(localized: String.LocalizationValue($0)) }
    }

    private static var legacyChineseDefaultTexts: [String] {
        guard let url = Bundle.main.url(forResource: "zh-Hans", withExtension: "lproj"),
              let bundle = Bundle(url: url)
        else { return [] }

        return defaultMessageKeys.map {
            bundle.localizedString(forKey: $0, value: $0, table: "Localizable")
        }
    }

    var smoke = false
    var wiggle = false
    var fireCount = 0
    private(set) var messages: [FireworkMessage]
    var selectedMessageID: FireworkMessage.ID? {
        didSet {
            defaults.set(selectedMessageID?.uuidString, forKey: Self.selectedMessageKey)
        }
    }

    var selectedMessage: FireworkMessage? {
        guard let selectedMessageID else { return nil }
        return messages.first { $0.id == selectedMessageID }
    }

    private let defaults: UserDefaults

    private init() {
        let defaults = UserDefaults.standard
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.messagesKey),
           let savedMessages = try? JSONDecoder().decode([FireworkMessage].self, from: data)
        {
            if savedMessages.map(\.text) == Self.legacyChineseDefaultTexts {
                messages = zip(savedMessages, Self.localizedDefaultTexts).map {
                    FireworkMessage(id: $0.0.id, text: $0.1)
                }
                Self.save(messages, to: defaults)
            } else {
                messages = savedMessages
            }
        } else {
            messages = Self.localizedDefaultTexts.map { FireworkMessage(text: $0) }
            Self.save(messages, to: defaults)
        }

        let savedID = defaults.string(forKey: Self.selectedMessageKey).flatMap(UUID.init(uuidString:))
        selectedMessageID = messages.contains { $0.id == savedID } ? savedID : messages.first?.id
        defaults.set(selectedMessageID?.uuidString, forKey: Self.selectedMessageKey)
    }

    @discardableResult
    func addMessage(_ rawText: String) -> Bool {
        let text = Self.normalized(rawText)
        guard !text.isEmpty else { return false }

        let message = FireworkMessage(text: text)
        messages.append(message)
        selectedMessageID = message.id
        saveMessages()
        return true
    }

    func removeSelectedMessage() {
        guard let selectedMessageID,
              let index = messages.firstIndex(where: { $0.id == selectedMessageID })
        else { return }

        messages.remove(at: index)
        if messages.indices.contains(index) {
            self.selectedMessageID = messages[index].id
        } else {
            self.selectedMessageID = messages.last?.id
        }
        saveMessages()
    }

    private static func normalized(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return String(trimmed.prefix(maximumMessageLength))
    }

    private func saveMessages() {
        Self.save(messages, to: defaults)
    }

    private static func save(_ messages: [FireworkMessage], to defaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(messages) else { return }
        defaults.set(data, forKey: Self.messagesKey)
    }
}
