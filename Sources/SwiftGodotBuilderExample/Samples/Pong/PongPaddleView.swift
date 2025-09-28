import SwiftGodot
import SwiftGodotBuilder
import SwiftGodotPatterns

func PongPaddleView(side: PongSide) -> CharacterBody2D$ {
  var shape: CapsuleShape2D {
    let s = CapsuleShape2D()
    s.height = Double(PongConfig.paddleHeight)
    s.radius = Double(PongConfig.paddleWidth)
    return s
  }

  var input = InputSnapshot()

  return CharacterBody2D$ {
    Sprite2D$()
      .res(\.texture, "paddle.png")
      .modulate(side == .left ? Color(r: 0, g: 1, b: 1, a: 1) : Color(r: 1, g: 0, b: 1, a: 1))

    CollisionShape2D$()
      .shape(shape)
  }
  .collisionLayer(Layers.paddles)
  .collisionMask(0)
  .onPhysicsProcess { cb, _ in
    input.poll(["\(side.rawValue)_move_up", "\(side.rawValue)_move_down"])
    let up = input.isDown("\(side.rawValue)_move_up")
    let down = input.isDown("\(side.rawValue)_move_down")
    if up == down {
      cb.velocity = .zero
      cb.moveAndSlide()
      return
    }

    let dir: Float = down ? 1 : -1
    cb.velocity = Vector2(0, PongConfig.paddleSpeed * dir)
    cb.moveAndSlide()

    let halfH = PongConfig.paddleHeight / 2

    if cb.position.y < halfH { cb.position.y = halfH; cb.velocity = .zero }
    if cb.position.y > PongConfig.viewH - halfH { cb.position.y = PongConfig.viewH - halfH; cb.velocity = .zero }
  }
}
