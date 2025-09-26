import Foundation
import SwiftGodot
import SwiftGodotBuilder
import SwiftGodotPatterns

extension ChatClientView {
  /// Sets the user's "is typing" status when the text input changes.
  func onTextChanged(_: LineEdit, text: String) {
    let has = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    commit(.setTyping(id: userId, typing: has, atMillis: nowMs()))
    typingCooldown.reset()
    if has { typingCooldown.start(1.2) } else { typingCooldown.stop() }
  }

  /// Called when the user presses Enter in the text input.
  func onTextSubmitted(lineEdit: LineEdit, text: String) {
    let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
    if text.isEmpty { return }
    commit(.sendMessage(author: userId, text: text, atMillis: nowMs()))
    lineEdit.text = ""
    commit(.setTyping(id: userId, typing: false, atMillis: nowMs()))
  }

  /// Called when the user presses the Send button.
  func onButtonPressed(_: Button) {
    guard let lineEdit = inputRef.node else { return }
    let text = (lineEdit.text as String).trimmingCharacters(in: .whitespacesAndNewlines)
    if text.isEmpty { return }
    commit(.sendMessage(author: userId, text: text, atMillis: nowMs()))
    lineEdit.text = ""
    commit(.setTyping(id: userId, typing: false, atMillis: nowMs()))
  }
}

private func nowMs() -> Int64 { Int64(Date().timeIntervalSince1970 * 1000.0) }
