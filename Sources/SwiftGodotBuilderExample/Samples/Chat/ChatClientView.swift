import Foundation
import SwiftGodot
import SwiftGodotBuilder
import SwiftGodotPatterns

struct ChatClientView: GView {
  let store: Store<ChatModel, ChatIntent, ChatEvent>
  let networkStore: Ref<NetworkStore>
  let mode: ChatNetMode

  let inputRef = Ref<LineEdit>()
  let userName = "User\(Int.random(in: 100 ... 999))"
  var userId: PeerID { networkStore.node?.peerID ?? 0 }
  var typingCooldown = GameTimer(duration: 1.2, repeats: false)

  var body: some GView {
    Node2D$ {
      CanvasLayer$ {
        VBoxContainer$ {
          ScrollContainer$ {
            VBoxContainer$()
              .onEvent(ChatEvent.self, appendChatMessages)
          }
          .followFocus(true)
          .verticalScrollMode(.auto)
          .size(.expandFill)
          .onEvent(ChatEvent.self, scrollToBottom)

          Label$()
            .text("")
            .onEvent(ChatEvent.self, updateIndicatorText)

          if case .client = mode {
            HBoxContainer$ {
              LineEdit$()
                .size(.expandFill)
                .on(\.textChanged, onTextChanged)
                .on(\.textSubmitted, onTextSubmitted)
                .ref(inputRef)

              Button$()
                .text("Send")
                .on(\.pressed, onButtonPressed)
            }
            .size(.fill)
          }
        }
        .anchors(.fullRect)
        .offsets(.fullRect, margin: 10)
      }
    }
    .onReady(onSceneReady)
    .onProcess { _, delta in
      typingCooldown.tick(delta: delta)
    }
  }

  public func onSceneReady(_: Node2D) {
    guard
      let ns = networkStore.node,
      let mp = ns.getTree()?.getMultiplayer(),
      mp.hasMultiplayerPeer()
    else {
      return
    }

    mp.connectedToServer.connect {
      sendIntent(.join(id: ns.peerID, name: userName))
    }

    _ = mp.connectionFailed.connect {
      GD.print("connection_failed")
    }

    _ = mp.serverDisconnected.connect {
      GD.print("server_disconnected")
    }
  }

  func sendIntent(_ intent: ChatIntent) {
    guard
      let ns = networkStore.node,
      let mp = ns.getTree()?.getMultiplayer(),
      mp.hasMultiplayerPeer() || mp.isServer()
    else {
      store.commit(intent)
      return
    }

    ns.sendIntents([intent])
  }
}

// MARK: Chat Events

// MARK: Signals
