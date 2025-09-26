import SwiftGodot
import SwiftGodotPatterns

public typealias PeerID = Int32

// Represents a participant in the chat session.
public struct ChatUser: Codable, Equatable, Hashable {
  public var id: PeerID
  public var displayName: String
  public var isTyping: Bool

  public init(id: PeerID, displayName: String, isTyping: Bool = false) {
    self.id = id
    self.displayName = displayName
    self.isTyping = isTyping
  }
}

// An immutable chat message payload replicated to clients.
public struct ChatMessage: Codable, Equatable, Hashable, Identifiable {
  public var id: Int64 // stable unique ID, assigned by server
  public var author: PeerID
  public var text: String
  public var sentAtMillis: Int64 // ID decides order, this is for display

  public init(id: Int64, author: PeerID, text: String, sentAtMillis: Int64) {
    self.id = id
    self.author = author
    self.text = text
    self.sentAtMillis = sentAtMillis
  }
}

// Authoritative chat model replicated via events/snapshots.
public struct ChatModel: Codable {
  public var users: [PeerID: ChatUser] = [:]
  public var messages: [ChatMessage] = []
  public var nextMessageId: Int64 = 1

  public var orderedMessages: [ChatMessage] { messages.sorted { $0.id < $1.id } }

  public mutating func upsertUser(_ u: ChatUser) { users[u.id] = u }

  public mutating func removeUser(_ id: PeerID) { users.removeValue(forKey: id) }

  public mutating func appendMessage(author: PeerID, text: String, now: Int64) -> ChatMessage {
    let m = ChatMessage(id: nextMessageId, author: author, text: text, sentAtMillis: now)
    nextMessageId += 1
    messages.append(m)
    return m
  }

  public mutating func setTyping(_ id: PeerID, _ typing: Bool, now _: Int64) {
    users[id]?.isTyping = typing
  }
}

// Intents are actions initiated by clients, sent to server for processing.
public enum ChatIntent: Codable {
  // Client Intents -> Server
  case join(id: PeerID, name: String)
  case leave(id: PeerID)
  case sendMessage(author: PeerID, text: String, atMillis: Int64)
  case setTyping(id: PeerID, typing: Bool, atMillis: Int64)
}

// Events are server-initiated updates sent to all clients.
public enum ChatEvent: Codable {
  // Server Events -> Clients
  case userJoined(id: PeerID, name: String)
  case userLeft(id: PeerID)
  case messagePosted(msg: ChatMessage)
  case typingChanged(id: PeerID, typing: Bool)
}

enum ChatNetMode {
  case server(port: Int32 = 8989, maxPeers: Int32 = 32)
  case client(host: String = "127.0.0.1", port: Int32 = 8989)
}
