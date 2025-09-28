import SwiftGodot
import SwiftGodotBuilder
import SwiftGodotPatterns

func PongWallView() -> StaticBody2D$ {
  StaticBody2D$ {
    CollisionShape2D$()
      .shape(RectangleShape2D(w: PongConfig.viewW + 64, h: 8))
  }
  .collisionLayer(Layers.walls)
  .collisionMask(Layers.ball)
}
