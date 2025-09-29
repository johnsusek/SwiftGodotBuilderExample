import SwiftGodot
import SwiftGodotBuilder
import SwiftGodotPatterns

enum PongConfig {
  static let viewW: Float = 320
  static let viewH: Float = 240
  static let paddleWidth: Float = 8
  static let paddleHeight: Float = 32
  static let paddleSpeed: Float = 300
  static let ballRadius: Float = 4
  static let ballSpeedStart: Float = 200
  static let ballSpeedMax: Float = 480
  static let ballSpeedGainOnPaddle: Float = 16
  static let minHorizontalDot: Float = 0.15
  static let maxBounceAngleDeg: Float = 45
}

let PongActions = Actions {
  ActionRecipes.axisUD(
    namePrefix: "left_move",
    device: 0,
    axis: .leftY,
    dz: 0.2,
    keyDown: .s,
    keyUp: .w,
    btnDown: .dpadDown,
    btnUp: .dpadUp
  )

  ActionRecipes.axisUD(
    namePrefix: "right_move",
    device: 1,
    axis: .leftY,
    dz: 0.2,
    keyDown: .down,
    keyUp: .up,
    btnDown: .dpadDown,
    btnUp: .dpadUp
  )
}

public enum PongSide: String, Codable { case left, right }

public enum PongActor: String { case ball, paddles, walls, goals }

enum Layers {
  static let ball = Physics2DLayer.alpha
  static let paddles = Physics2DLayer.beta
  static let walls = Physics2DLayer.gamma
  static let goals = Physics2DLayer.delta
}

@inline(__always) func deg2rad(_ d: Float) -> Float { d * .pi / 180 }
