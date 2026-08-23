import SwiftUI

/// Paddock chat: one shared room per race weekend, on CloudKit.
struct ChatView: View {
    @State private var model = ChatViewModel()
    @State private var draft = ""
    @State private var nicknameDraft = ""

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            RadialGradient(
                colors: [Theme.f1Red.opacity(0.14), .clear],
                center: .top, startRadius: 0, endRadius: 380
            )
            .ignoresSafeArea()

            switch model.state {
            case .checking:
                LoadingView()
            case .needsICloud:
                needsICloud
            case .ready:
                if !model.agreedToRules {
                    rulesGate
                } else if model.nickname.isEmpty {
                    nicknamePrompt
                } else {
                    chatRoom
                }
            }
        }
        .task { await model.start() }
        .onDisappear { model.stop() }
    }

    // MARK: - Gates

    private var needsICloud: some View {
        VStack(spacing: 12) {
            Text("☁️")
                .font(.system(size: 40))
            Text("SIGN IN TO iCLOUD")
                .font(.f1(20).italic())
                .foregroundStyle(.white)
            Text("The paddock chat uses your iCloud account — no sign-up needed. Enable iCloud in Settings and come back.")
                .font(.subheadline)
                .foregroundStyle(Theme.dimText)
                .multilineTextAlignment(.center)
        }
        .padding(30)
    }

    private var rulesGate: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("PADDOCK RULES")
                .font(.f1(24).italic())
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 8) {
                Label("Be respectful — rivalry yes, abuse no.", systemImage: "flag.checkered")
                Label("No hate speech, harassment, or spam. Zero tolerance.", systemImage: "hand.raised.fill")
                Label("Long-press any message to report or block.", systemImage: "exclamationmark.bubble")
                Label("Reported content is reviewed and removed within 24 hours.", systemImage: "clock")
            }
            .font(.system(size: 14))
            .foregroundStyle(.white.opacity(0.85))

            Button {
                model.agreeToRules()
            } label: {
                Text("I AGREE — LET ME IN")
                    .font(.f1(15).italic())
                    .tracking(1)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Theme.f1Red, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.card)
                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.cardStroke, lineWidth: 1))
        )
        .padding(20)
    }

    private var nicknamePrompt: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("PICK A PADDOCK NAME")
                .font(.f1(22).italic())
                .foregroundStyle(.white)
            Text("This is how other fans see you. You can't change it often, so choose wisely.")
                .font(.subheadline)
                .foregroundStyle(Theme.dimText)
            TextField("e.g. GravelTrapHero", text: $nicknameDraft)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(.white)
            Button {
                model.saveNickname(nicknameDraft)
            } label: {
                Text("JOIN THE PADDOCK")
                    .font(.f1(15).italic())
                    .tracking(1)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        nicknameDraft.trimmingCharacters(in: .whitespaces).count >= 3 ? Theme.f1Red : Color.gray.opacity(0.3),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
            }
            .buttonStyle(.plain)
            .disabled(nicknameDraft.trimmingCharacters(in: .whitespaces).count < 3)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.card)
                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.cardStroke, lineWidth: 1))
        )
        .padding(20)
    }

    // MARK: - Chat room

    private var chatRoom: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("PADDOCK CHAT")
                    .font(.f1(30).italic())
                    .foregroundStyle(.white)
                Text(model.roundTitle.uppercased())
                    .font(.f1(12, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Theme.dimText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 10)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        if model.messages.isEmpty {
                            Text("Nothing here yet — be the first voice in the paddock. 🏁")
                                .font(.subheadline)
                                .foregroundStyle(Theme.dimText)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)
                        }
                        ForEach(model.messages) { message in
                            ChatBubble(message: message, isMine: model.isMine(message))
                                .id(message.id)
                                .contextMenu {
                                    if !model.isMine(message) {
                                        Button(role: .destructive) {
                                            model.report(message)
                                        } label: {
                                            Label("Report message", systemImage: "exclamationmark.bubble")
                                        }
                                        Button(role: .destructive) {
                                            model.block(message)
                                        } label: {
                                            Label("Block this user", systemImage: "hand.raised")
                                        }
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
                .onChange(of: model.messages) { _, messages in
                    if let last = messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            inputBar
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Say something…", text: $draft, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Theme.card)
                        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.cardStroke, lineWidth: 1))
                )
                .foregroundStyle(.white)

            Button {
                let text = draft
                draft = ""
                Task { await model.send(text) }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(draft.trimmingCharacters(in: .whitespaces).isEmpty ? Theme.dimText : Theme.f1Red)
            }
            .buttonStyle(.plain)
            .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty || model.isSending)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    let isMine: Bool

    var body: some View {
        VStack(alignment: isMine ? .trailing : .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(message.sender)
                    .font(.f1(12).italic())
                    .foregroundStyle(isMine ? Theme.f1Red : .white.opacity(0.8))
                Text(message.date.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.faintText)
            }
            Text(ChatModeration.cleaned(message.text))
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isMine ? Theme.f1Red.opacity(0.25) : Theme.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(isMine ? Theme.f1Red.opacity(0.4) : Theme.cardStroke, lineWidth: 1)
                        )
                )
        }
        .frame(maxWidth: .infinity, alignment: isMine ? .trailing : .leading)
    }
}
