import Foundation
import Observation

@Observable
@MainActor
final class ChatViewModel {
    enum State: Equatable {
        case checking
        case needsICloud
        case ready
    }

    var state: State = .checking
    var messages: [ChatMessage] = []
    var nickname: String = UserDefaults.standard.string(forKey: "chatNickname") ?? ""
    var agreedToRules: Bool = UserDefaults.standard.bool(forKey: "chatRulesAgreed")
    var isSending = false
    var round: String = ""
    var roundTitle: String = ""

    private var currentUserId: String?
    private var pollTask: Task<Void, Never>?

    func start() async {
        guard await ChatService.accountAvailable() else {
            state = .needsICloud
            return
        }
        currentUserId = await ChatService.currentUserId()
        state = .ready

        // Chat room is scoped to the upcoming race weekend.
        if let race = try? await F1API.nextRace() {
            round = "\(race.season)-\(race.round)"
            roundTitle = race.raceName
        } else {
            round = "paddock"
            roundTitle = "The Paddock"
        }

        await refresh()
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(6))
                await self?.refresh()
            }
        }
    }

    func stop() {
        pollTask?.cancel()
        pollTask = nil
    }

    func refresh() async {
        guard state == .ready, !round.isEmpty else { return }
        if let fetched = try? await ChatService.messages(round: round) {
            let blocked = ChatModeration.blockedUsers
            messages = fetched.filter { !blocked.contains($0.senderId) }
        }
    }

    func send(_ text: String) async {
        let trimmed = ChatModeration.cleaned(text.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !trimmed.isEmpty, !nickname.isEmpty else { return }
        isSending = true
        defer { isSending = false }
        try? await ChatService.send(text: String(trimmed.prefix(280)), sender: nickname, round: round)
        await refresh()
    }

    func saveNickname(_ name: String) {
        let cleaned = ChatModeration.cleaned(name.trimmingCharacters(in: .whitespacesAndNewlines))
        nickname = String(cleaned.prefix(20))
        UserDefaults.standard.set(nickname, forKey: "chatNickname")
    }

    func agreeToRules() {
        agreedToRules = true
        UserDefaults.standard.set(true, forKey: "chatRulesAgreed")
    }

    func isMine(_ message: ChatMessage) -> Bool {
        message.senderId == currentUserId
    }

    func report(_ message: ChatMessage) {
        Task { await ChatService.report(message, reason: "user report") }
        messages.removeAll { $0.id == message.id }
    }

    func block(_ message: ChatMessage) {
        ChatModeration.block(message.senderId)
        messages.removeAll { $0.senderId == message.senderId }
    }
}
