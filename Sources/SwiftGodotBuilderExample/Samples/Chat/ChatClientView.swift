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
      send(.join(id: ns.peerID, name: userName))
    }

    _ = mp.connectionFailed.connect {
      GD.print("connection_failed")
    }

    _ = mp.serverDisconnected.connect {
      GD.print("server_disconnected")
    }
  }
}

// MARK: Chat Events

extension ChatClientView {
  private func indicatorLine(userId: PeerID) -> String {
    let typing = store.model.users.values.filter { $0.isTyping && $0.id != userId }.map(\.displayName)
    if typing.isEmpty { return "" }
    if typing.count == 1 { return "\(typing[0]) is typing…" }
    if typing.count == 2 { return "\(typing[0]) and \(typing[1]) are typing…" }
    return "\(typing[0]), \(typing[1]) and \(typing.count - 2) others are typing…"
  }

  func updateIndicatorText(label: Label, ev: ChatEvent) {
    switch ev {
    case .typingChanged, .messagePosted:
      label.text = indicatorLine(userId: userId)
    default: break
    }
  }

  func scrollToBottom(scroll: ScrollContainer, ev: ChatEvent) {
    switch ev {
    case .userJoined, .userLeft, .messagePosted:
      Engine.onNextFrame {
        let sprites: [VBoxContainer] = scroll.getChildren()
        guard let vb = sprites.first else { return }
        scroll.scrollVertical = Int32(vb.getMinimumSize().y)
      }
    default: break
    }
  }

  func appendChatMessages(vbox: VBoxContainer, ev: ChatEvent) {
    switch ev {
    case let .userJoined(id, name):
      let row = Label$().text("• \(name) joined (\(id))").modulate(Color(r: 0.8, g: 0.8, b: 0.9, a: 1))
      vbox.addChild(node: row.toNode())

    case let .userLeft(id):
      let name = store.model.users[id]?.displayName ?? "#\(id)"
      let row = Label$().text("\(name) left").modulate(Color(r: 0.8, g: 0.8, b: 0.9, a: 1))
      vbox.addChild(node: row.toNode())

    case let .messagePosted(msg):
      let name = "#\(msg.author)"
      let row = HBoxContainer$ {
        Label$().text("\(name):").size(.fill)
        Label$().text(msg.text).size(.expandFill)
      }
      vbox.addChild(node: row.toNode())

    default: break
    }
  }
}

// MARK: Signals

extension ChatClientView {
  private func send(_ intent: ChatIntent) {
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

  func onTextChanged(_: LineEdit, text: String) {
    let has = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    send(.setTyping(id: userId, typing: has, atMillis: nowMs()))
    typingCooldown.reset()
    if has { typingCooldown.start(1.2) } else { typingCooldown.stop() }
  }

  func onTextSubmitted(lineEdit: LineEdit, text: String) {
    let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
    if text.isEmpty { return }
    send(.sendMessage(author: userId, text: text, atMillis: nowMs()))
    lineEdit.text = ""
    send(.setTyping(id: userId, typing: false, atMillis: nowMs()))
  }

  func onButtonPressed(_: Button) {
    guard let lineEdit = inputRef.node else { return }
    let text = (lineEdit.text as String).trimmingCharacters(in: .whitespacesAndNewlines)
    if text.isEmpty { return }
    send(.sendMessage(author: userId, text: text, atMillis: nowMs()))
    lineEdit.text = ""
    send(.setTyping(id: userId, typing: false, atMillis: nowMs()))
  }
}

private func nowMs() -> Int64 { Int64(Date().timeIntervalSince1970 * 1000.0) }
