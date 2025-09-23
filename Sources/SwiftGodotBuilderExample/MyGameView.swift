import Foundation
import SwiftGodot
import SwiftGodotBuilder
import SwiftGodotPatterns

struct MyGameView: GView {
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
