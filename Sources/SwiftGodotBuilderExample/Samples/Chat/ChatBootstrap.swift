import Foundation
import SwiftGodot
import SwiftGodotBuilder
import SwiftGodotPatterns

enum ChatBootstrap {
  private static func nowMs() -> Int64 { Int64(Date().timeIntervalSince1970 * 1000.0) }

  private static let store = Store<ChatModel, ChatIntent, ChatEvent>(model: .init())

  // Pure game system: consumes client `ChatIntent`s, mutates `ChatModel`, emits `ChatEvent`s.
  private static let gameSystem = GameSystem<ChatModel, ChatIntent, ChatEvent> { intents, model, out in
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

  // Wires a `NetworkStore` to the shared `Store`, then brings up ENet in either
  // server or client mode and attaches it to `MultiplayerAPI`.
  private static func configureNetworkStore(_ netStore: NetworkStore, mode: ChatNetMode) {
    guard let mp = Engine.getSceneTree()?.getMultiplayer() else {
      GD.print("Failed to get multiplayer")
      return
    }

    netStore.wire(to: store)

    // Create and attach the ENet peer based on server or client
    switch mode {
    case let .server(port, maxPeers):
      let enet = ENetMultiplayerPeer()
      let err = enet.createServer(port: port, maxClients: maxPeers)
      if err != .ok { GD.print("ENet createServer failed:", err); return }

      mp.multiplayerPeer = enet
      GD.print("Server listening on port \(port), maxPeers=\(maxPeers)")

      // Join-in-progress: send an authoritative snapshot to just-connected peers.
      _ = mp.peerConnected.connect { _ in
        let snap = NetworkStore.ModelSnapshot(tick: nowMs(), model: Self.store.model)
        netStore.sendModelState(snap)
      }

    case let .client(host, port):
      let enet = ENetMultiplayerPeer()
      let err = enet.createClient(address: host, port: port)
      if err != .ok { GD.print("ENet createClient failed:", err); return }

      mp.multiplayerPeer = enet
      GD.print("Client connecting to \(host):\(port)")
    }
  }

  // Assembles the scene
  // We use this wrapper because the server doesn't need the UI.
  static func make() -> Node {
    register(type: GProcessRelay.self) // for .onReady
    register(type: NetworkStore.self)

    store.register(gameSystem)

    return makeGameRoot()
  }

  static func makeGameRoot() -> Node {
    let mode = ChatOpts.parseChatCLI()

    // If both client and server ran the UI, we would put this in ChatView
    // rather than using a ref and wrapper view.
    let networkStore = Ref<NetworkStore>()

    let gameRootView = Node$("GameRoot") {
      // The server is just this node:
      GNode<NetworkStore>("NetSync")
        .configure { netStore in configureNetworkStore(netStore, mode: mode) }
        .ref(networkStore)

      // The client also has the UI:
      if case .client = mode {
        ChatClientView(store: store, networkStore: networkStore, mode: mode)
      }
    }

    return gameRootView.toNode()
  }
}
