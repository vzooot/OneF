import CloudKit
import Foundation

struct ChatMessage: Identifiable, Equatable {
    let id: CKRecord.ID
    let text: String
    let sender: String
    let senderId: String
    let date: Date

    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool { lhs.id == rhs.id }
}

/// Race-weekend chat on CloudKit's public database: no accounts, no servers —
/// users are identified by their iCloud account.
enum ChatService {
    static let container = CKContainer(identifier: "iCloud.com.woqomoqo.OneF")
    private static var database: CKDatabase { container.publicCloudDatabase }

    static func accountAvailable() async -> Bool {
        (try? await container.accountStatus()) == .available
    }

    /// A stable, opaque id for the current user (used for blocking).
    static func currentUserId() async -> String? {
        (try? await container.userRecordID())?.recordName
    }

    /// Latest messages for one race weekend, oldest first.
    static func messages(round: String, limit: Int = 80) async throws -> [ChatMessage] {
        let query = CKQuery(
            recordType: "Message",
            predicate: NSPredicate(format: "round == %@", round)
        )
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        do {
            let (results, _) = try await database.records(matching: query, resultsLimit: limit)
            return results
                .compactMap { _, result in try? result.get() }
                .compactMap { record in
                    guard let text = record["text"] as? String,
                          let sender = record["sender"] as? String,
                          let senderId = record["senderId"] as? String,
                          let date = record.creationDate else { return nil }
                    return ChatMessage(id: record.recordID, text: text, sender: sender, senderId: senderId, date: date)
                }
                .reversed()
        } catch let error as CKError where error.code == .unknownItem || error.code == .invalidArguments {
            // Record type doesn't exist yet (first ever run) — empty room.
            return []
        }
    }

    static func send(text: String, sender: String, round: String) async throws {
        let record = CKRecord(recordType: "Message")
        record["text"] = text
        record["sender"] = sender
        record["round"] = round
        record["senderId"] = await currentUserId() ?? "unknown"
        _ = try await database.save(record)
    }

    /// Files a report record the developer reviews in the CloudKit dashboard.
    static func report(_ message: ChatMessage, reason: String) async {
        let record = CKRecord(recordType: "Report")
        record["messageRecordName"] = message.id.recordName
        record["messageText"] = message.text
        record["messageSenderId"] = message.senderId
        record["reason"] = reason
        _ = try? await database.save(record)
    }
}

/// Client-side content rules: required by App Review for user-generated
/// content, and just good manners.
enum ChatModeration {
    private static let blockedWordsKey = "chatBlockedUsers"

    private static let profanity: [String] = [
        "fuck", "shit", "bitch", "cunt", "asshole", "faggot", "nigger", "nigga",
        "retard", "whore", "slut", "wanker", "dickhead",
    ]

    /// Masks profane fragments rather than refusing the message.
    static func cleaned(_ text: String) -> String {
        var result = text
        for word in profanity {
            while let range = result.range(of: word, options: [.caseInsensitive, .diacriticInsensitive]) {
                result.replaceSubrange(range, with: String(repeating: "•", count: word.count))
            }
        }
        return result
    }

    static var blockedUsers: Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: blockedWordsKey) ?? [])
    }

    static func block(_ senderId: String) {
        var users = blockedUsers
        users.insert(senderId)
        UserDefaults.standard.set(Array(users), forKey: blockedWordsKey)
    }
}
