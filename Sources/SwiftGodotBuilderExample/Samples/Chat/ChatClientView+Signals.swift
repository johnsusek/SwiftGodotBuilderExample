import Foundation
import SwiftGodot
import SwiftGodotBuilder
import SwiftGodotPatterns

extension ChatClientView {
  /// Called when the user presses Enter in the text input.
  func onTextSubmitted(lineEdit: LineEdit, text: String) {
    let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
    if text.isEmpty { return }
    commit(.sendMessage(author: userId, text: text, atMillis: nowMs()))
    lineEdit.text = ""
  }

  /// Called when the user presses the Send button.
  func onButtonPressed(_: Button) {
    guard let lineEdit = inputRef.node else { return }
    let text = (lineEdit.text as String).trimmingCharacters(in: .whitespacesAndNewlines)
    if text.isEmpty { return }
    commit(.sendMessage(author: userId, text: text, atMillis: nowMs()))
    lineEdit.text = ""
  }
}

private func nowMs() -> Int64 { Int64(Date().timeIntervalSince1970 * 1000.0) }
