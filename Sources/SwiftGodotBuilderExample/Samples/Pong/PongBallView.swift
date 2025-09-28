import SwiftGodot
import SwiftGodotBuilder
import SwiftGodotPatterns

func PongBallView() -> CharacterBody2D$ {
  let audioRef = Ref<AudioStreamPlayer2D>()
  let ballRef = Ref<CharacterBody2D>()

  var speed: Float = PongConfig.ballSpeedStart

  return CharacterBody2D$ {
    AudioStreamPlayer2D$()
      .res(\.stream, "ball.wav")
      .ref(audioRef)

    Sprite2D$()
      .res(\.texture, "ball.png")
      .onReady { _ in
        serveBall(ballRef.node, toward: Bool.random() ? .left : .right)
      }

    CollisionShape2D$()
      .shape(CircleShape2D(radius: Double(PongConfig.ballRadius)))
  }
  .position(Vector2(PongConfig.viewW / 2, PongConfig.viewH / 2))
  .collisionLayer(Layers.ball)
  .collisionMask([Layers.paddles, Layers.walls, Layers.goals])
  .position(Vector2(PongConfig.viewW * 0.5, PongConfig.viewH * 0.5))
  .onReady { _ in
    serveBall(ballRef.node, toward: Bool.random() ? .left : .right)
  }
  .onPhysicsProcess { cb, delta in
    var remaining = Float(delta)
    var attempts = 4
    while attempts > 0 && remaining > 0 {
      let travel = cb.velocity * remaining
      guard let hit = cb.moveAndCollide(motion: travel) else { break }

      let normal = hit.getNormal()
      var newDir = cb.velocity.bounce(n: normal).normalized()

      if let collider = hit.getCollider() as? CharacterBody2D,
         collider.collisionLayer == Layers.paddles.rawValue
      {
        let impactY = Float(hit.getPosition().y)
        let offset = (impactY - collider.position.y) / (PongConfig.paddleHeight * 0.5)
        let clamped = max(-1, min(1, offset))
        let angle = deg2rad(PongConfig.maxBounceAngleDeg) * clamped
        let facing: Float = (cb.position.x < PongConfig.viewW * 0.5) ? 1 : -1
        newDir = Vector2(facing, 0).rotated(angle: Double(angle)).normalized()
        speed = min(speed + PongConfig.ballSpeedGainOnPaddle, PongConfig.ballSpeedMax)
        audioRef.node?.play()
      }

      cb.velocity = newDir * speed

      // Continue with any remainder in this step.
      let traveledLen = Float(hit.getTravel().length())
      let totalLen = Float(travel.length())
      let remainFrac = max(0, min(1, 1 - (totalLen == 0 ? 1 : traveledLen / totalLen)))
      remaining *= remainFrac
      attempts -= 1
    }

    if remaining > 0 { _ = cb.moveAndCollide(motion: cb.velocity * remaining) }
  }
  .ref(ballRef)
}
