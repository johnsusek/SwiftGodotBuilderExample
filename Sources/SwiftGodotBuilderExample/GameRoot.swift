import Foundation
import SwiftGodot
import SwiftGodotBuilder

// This is the root scene in the .tscn file.
// It creates and adds the actual game view as a child node.
//
// You don't have to do it this way, but it's a simple way to get started.
//
// If you have an existing Godot project, you can use SwiftGodotBuilder
// views as children of your existing nodes.
@Godot
class GameRoot: Node2D {
  override func _ready() {
    // Uncomment one of these views to try it out.
    // Then find the source code in the Samples/ folder to see how it works.

    let view = ActionsView()
    // let view = PongView()
    // let view = BreakoutView()
    // let view = SpaceInvadersView()
    // let view = HUDView()
    // let view = AsepriteView()
    // let view = PlaygroundView()
    // let view = DinoGameView()

    addChild(node: view.toNode())
  }
}
