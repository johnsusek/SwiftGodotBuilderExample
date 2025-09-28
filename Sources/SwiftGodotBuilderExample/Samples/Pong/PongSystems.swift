import SwiftGodot
import SwiftGodotBuilder
import SwiftGodotPatterns

func serveBall(_ ball: CharacterBody2D?, toward side: PongSide) {
  guard let ball else { return }

  ball.position = Vector2(PongConfig.viewW * 0.5, PongConfig.viewH * 0.5)

  let baseX: Float = side == .left ? -1 : 1
  let randomAngle = Float.random(in: -deg2rad(15) ... deg2rad(15))
  let dir = Vector2(baseX, 0).rotated(angle: Double(randomAngle)).normalized()

  ball.velocity = dir * PongConfig.ballSpeedStart
}
