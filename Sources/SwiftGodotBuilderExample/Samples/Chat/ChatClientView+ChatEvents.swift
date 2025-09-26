import Foundation
import SwiftGodot
import SwiftGodotBuilder
import SwiftGodotPatterns

extension ChatClientView {
  /// Scrolls the chat to the bottom when new messages arrive.
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

  /// Appends new chat messages and join/leave notifications to the chat log.
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
    }
  }
}
