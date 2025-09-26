import Foundation
import SwiftGodot
import SwiftGodotBuilder
import SwiftGodotPatterns

extension ChatClientView {
  func onTextChanged(_: LineEdit, text: String) {
    let has = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    sendIntent(.setTyping(id: userId, typing: has, atMillis: nowMs()))
    typingCooldown.reset()
    if has { typingCooldown.start(1.2) } else { typingCooldown.stop() }
  }

  func onTextSubmitted(lineEdit: LineEdit, text: String) {
    let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
    if text.isEmpty { return }
    sendIntent(.sendMessage(author: userId, text: text, atMillis: nowMs()))
    lineEdit.text = ""
    sendIntent(.setTyping(id: userId, typing: false, atMillis: nowMs()))
  }

  func onButtonPressed(_: Button) {
    guard let lineEdit = inputRef.node else { return }
    let text = (lineEdit.text as String).trimmingCharacters(in: .whitespacesAndNewlines)
    if text.isEmpty { return }
    sendIntent(.sendMessage(author: userId, text: text, atMillis: nowMs()))
    lineEdit.text = ""
    sendIntent(.setTyping(id: userId, typing: false, atMillis: nowMs()))
  }
}

private func nowMs() -> Int64 { Int64(Date().timeIntervalSince1970 * 1000.0) }
