import Foundation
import SwiftGodot
import SwiftGodotBuilder
import SwiftGodotPatterns

extension ChatClientView {
  private func buildIndicatorText(userId: PeerID) -> String {
    let typing = store.model.users.values.filter { $0.isTyping && $0.id != userId }.map(\.displayName)
    if typing.isEmpty { return "" }
    if typing.count == 1 { return "\(typing[0]) is typing…" }
    if typing.count == 2 { return "\(typing[0]) and \(typing[1]) are typing…" }
    return "\(typing[0]), \(typing[1]) and \(typing.count - 2) others are typing…"
  }

  func updateIndicatorText(label: Label, ev: ChatEvent) {
    switch ev {
    case .typingChanged, .messagePosted:
      label.text = buildIndicatorText(userId: userId)
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
