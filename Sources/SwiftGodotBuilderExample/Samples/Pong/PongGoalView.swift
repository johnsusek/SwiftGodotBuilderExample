import SwiftGodot
import SwiftGodotBuilder
import SwiftGodotPatterns

func PongGoalView() -> Area2D$ {
  Area2D$ {
    CollisionShape2D$()
      .shape(RectangleShape2D(w: 16, h: PongConfig.viewH + 64))
  }
  .collisionMask(Layers.ball)
  .collisionLayer(Layers.goals)
}
