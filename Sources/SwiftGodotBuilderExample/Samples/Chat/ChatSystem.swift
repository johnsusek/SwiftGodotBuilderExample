import SwiftGodotPatterns

// Pure game system: consumes client `ChatIntent`s, mutates `ChatModel`, emits `ChatEvent`s.
let ChatSystem = GameSystem<ChatModel, ChatIntent, ChatEvent> { intents, model, events in
  if intents.isEmpty { return }

  for intent in intents {
    switch intent {
    case let .join(id, name):
      model.upsertUser(.init(id: id, displayName: name))
      events.append(.userJoined(id: id, name: name))

    case let .leave(id):
      model.removeUser(id)
      events.append(.userLeft(id: id))

    case let .sendMessage(author, text, atMillis):
      // Ignore whitespace-only messages to keep the log clean.
      let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
      if trimmed.isEmpty { continue }
      let msg = model.appendMessage(author: author, text: trimmed, now: atMillis)
      events.append(.messagePosted(msg: msg))
    }
  }
}
