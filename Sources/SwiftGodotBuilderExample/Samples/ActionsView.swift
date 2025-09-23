import Foundation
import SwiftGodot
import SwiftGodotBuilder
import SwiftGodotPatterns

struct ActionsView: GView {
  init() {
    let actions = Actions {
      Action("up") { Key(.up) }
      Action("down") { Key(.down) }
      Action("left") { Key(.left) }
      Action("right") { Key(.right) }
    }
    actions.install()
  }

  var body: some GView {
    return CanvasLayer$ {
      Label$()
        .text("Hello, World!")
        .onAction("up") { label in label.text = "up pressed" }
        .onAction("down") { label in label.text = "down pressed" }
        .onAction("left") { label in label.text = "left pressed" }
        .onAction("right") { label in label.text = "right pressed" }
    }
  }
}
