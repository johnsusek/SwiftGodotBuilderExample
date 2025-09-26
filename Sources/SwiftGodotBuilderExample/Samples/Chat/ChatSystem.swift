import SwiftGodotPatterns

// Pure game system: consumes client `ChatIntent`s, mutates `ChatModel`, emits `ChatEvent`s.
let ChatSystem = GameSystem<ChatModel, ChatIntent, ChatEvent> { intents, model, out in
  if intents.isEmpty { return }

  for intent in intents {
    switch intent {
    case let .join(id, name):
      model.upsertUser(.init(id: id, displayName: name))
      out.append(.userJoined(id: id, name: name))

    case let .leave(id):
      model.removeUser(id)
      out.append(.userLeft(id: id))

    case let .sendMessage(author, text, atMillis):
      // Ignore whitespace-only messages to keep the log clean.
      let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
      if trimmed.isEmpty { continue }
      let msg = model.appendMessage(author: author, text: trimmed, now: atMillis)
      out.append(.messagePosted(msg: msg))

    case let .setTyping(id, typing, atMillis):
      model.setTyping(id, typing, now: atMillis)
      out.append(.typingChanged(id: id, typing: typing))
    }
  }
}
