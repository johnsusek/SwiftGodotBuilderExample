import SwiftGodot

// This is the root scene in the .tscn file.
// It creates and adds the actual game view as a child node.
//
// You don't have to do it this way, but it's a simple way to get started.
//
// If you have an existing Godot project, you can use SwiftGodotBuilder
// views as children of your existing nodes.

@Godot
final class GameRoot: Node2D {
  override func _ready() {
    let view = PongView()
    // let view = BreakoutView()
    // let view = SpaceInvadersView()
    // let view = HUDView()
    // let view = ActionsView()
    // let view = AsepriteView()
    // let view = PlaygroundView()
    // let view = DinoGameView()

    let root = view.toNode()

    // let root = ChatBootstrap.make()

    addChild(node: root)
  }
}
