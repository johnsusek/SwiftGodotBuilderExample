import Foundation
import SwiftGodot
import SwiftGodotBuilder
import SwiftGodotPatterns

private let store = Store<ChatModel, ChatIntent, ChatEvent>(model: .init())

// We use this wrapper because the server doesn't need the UI.
func ChatRootView() -> any GView {
  register(type: GProcessRelay.self) // for .onReady
  register(type: NetworkStore.self)

  store.register(ChatSystem)

  return makeNode()
}

func makeNode() -> any GView {
  let mode = ChatOpts.parseChatCLI()
  let networkStore = Ref<NetworkStore>()

  return Node$("GameRoot") {
    GNode<NetworkStore>("NetSync")
      .configure { netStore in
        netStore.wire(to: store)
        configureMultiplayer(mode: mode, for: netStore)
      }
      .ref(networkStore)

    if case .client = mode {
      ChatClientView(store: store, networkStore: networkStore, mode: mode)
    }
  }
}

// Brings up ENet in either server or client mode and attaches it to `MultiplayerAPI`.
private func configureMultiplayer(mode: ChatNetMode, for netStore: NetworkStore) {
  guard let mpApi = Engine.getSceneTree()?.getMultiplayer() else { return }

  switch mode {
  // Server
  case let .server(port, maxPeers):
    let enet = ENetMultiplayerPeer()
    let err = enet.createServer(port: port, maxClients: maxPeers)
    if err != .ok { GD.print("ENet createServer failed:", err); return }

    mpApi.multiplayerPeer = enet
    GD.print("Server listening on port \(port), maxPeers=\(maxPeers)")

    // Join-in-progress: send an authoritative snapshot to just-connected peers.
    _ = mpApi.peerConnected.connect { _ in
      let snap = NetworkStore.ModelSnapshot(tick: nowMs(), model: store.model)
      netStore.sendModelState(snap)
    }

  // Client
  case let .client(host, port):
    let enet = ENetMultiplayerPeer()
    let err = enet.createClient(address: host, port: port)
    if err != .ok { GD.print("ENet createClient failed:", err); return }

    mpApi.multiplayerPeer = enet
    GD.print("Client connecting to \(host):\(port)")
  }
}

private func nowMs() -> Int64 { Int64(Date().timeIntervalSince1970 * 1000.0) }
