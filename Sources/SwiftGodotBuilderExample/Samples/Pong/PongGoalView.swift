import SwiftGodot
import SwiftGodotBuilder
import SwiftGodotPatterns

func PongGoalView(side: PongSide) -> Area2D$ {
  Area2D$ {
    CollisionShape2D$()
      .shape(RectangleShape2D(w: 16, h: PongConfig.viewH + 64))
  }
  .collisionMask(Layers.ball)
  .collisionLayer(Layers.goals)
  .on(\.bodyEntered) { area, _ in
    let isServer = area.getTree()?.getMultiplayer()?.isServer() == true
    if !isServer { return }
    GlobalEventBuses.hub(PongControl.self).publish(.serve(side == .left ? .right : .left))
  }
}
