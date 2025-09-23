import Foundation
import SwiftGodot
import SwiftGodotBuilder

@Godot
class MyGame: Node2D {
  let actions = Actions {
    Action("up") { Key(.up) }
    Action("down") { Key(.down) }
    Action("left") { Key(.left) }
    Action("right") { Key(.right) }
  }

  override func _ready() {
    actions.install()
    let view = MyGameView()
    addChild(node: view.toNode())
  }
}
