import SwiftGodot
import SwiftGodotBuilder
import SwiftGodotPatterns

// MARK: - Views

struct PongBallView: GView {
  var body: some GView {
    let audio = Ref<AudioStreamPlayer2D>()

    return GNode<Ball> {
      AudioStreamPlayer2D$()
        .res(\.stream, "ball.wav")
        .ref(audio)

      Sprite2D$()
        .res(\.texture, "ball.png")

      CollisionShape2D$()
        .shape(RectangleShape2D(w: PongConfig.ballRadius * 2, h: PongConfig.ballRadius * 2))
    }
    .on(\.areaEntered) { ball, other in
      guard other is Paddle else { return }
      ball.velocity.x = -ball.velocity.x
      audio.node?.play()
    }
  }
}

struct PongPaddleView: GView {
  let side: String
  let position: Vector2
  let color: Color

  var body: some GView {
    GNode<Paddle> {
      Sprite2D$()
        .res(\.texture, "paddle.png")
        .modulate(color)

      CollisionShape2D$()
        .shape(RectangleShape2D(w: PongConfig.paddleWidth, h: PongConfig.paddleHeight))
    }
    .configure { $0.side = side }
    .position(position)
  }
}

struct PongView: GView {
  init() {
    GodotRegistry.append([Ball.self, Paddle.self])
    PongActions.install()
  }

  var halfViewH: Float { PongConfig.viewH / 2 }

  var body: some GView {
    Node2D$ {
      Sprite2D$()
        .res(\.texture, "separator.png")
        .position(Vector2(PongConfig.viewW / 2, halfViewH))

      PongBallView()

      PongPaddleView(
        side: "left",
        position: Vector2(PongConfig.paddleWidth, halfViewH),
        color: Color(r: 0, g: 1, b: 1, a: 1)
      )

      PongPaddleView(
        side: "right",
        position: Vector2(PongConfig.viewW - PongConfig.paddleWidth, halfViewH),
        color: Color(r: 1, g: 0, b: 1, a: 1)
      )
    }
  }
}

// MARK: - Nodes

@Godot
final class Ball: Area2D {
  var ballVelocity = PongConfig.ballVelocity
  var ballRadius: Float { PongConfig.ballRadius }
  var velocity = Vector2(PongConfig.ballVelocity, PongConfig.ballVelocity)

  override func _physicsProcess(delta: Double) {
    position.x += velocity.x * Float(delta)
    position.y += velocity.y * Float(delta)

    let minY = ballRadius, maxY = visibleSize.y - ballRadius

    if position.y < minY || position.y > maxY {
      position.y = min(max(position.y, minY), maxY)
      velocity.y = -velocity.y
    }

    if position.x <= -ballRadius || position.x >= visibleSize.x + ballRadius {
      position = visibleCenter
      velocity = Vector2(ballVelocity, ballVelocity)
    }
  }
}

@Godot
final class Paddle: Area2D {
  var side = "left"

  private let halfH = PongConfig.paddleHeight / 2

  override func _physicsProcess(delta: Double) {
    let down = Input.getActionStrength(action: StringName("\(side)_move_down"))
    let up = Input.getActionStrength(action: StringName("\(side)_move_up"))
    let dir = down - up

    if dir == 0 { return }

    position.y += PongConfig.paddleSpeed * Float(dir * delta)
    position.y = min(max(position.y, halfH), visibleSize.y - halfH)
  }
}

// MARK: - Config

private enum PongConfig {
  static let paddleWidth: Float = 8
  static let paddleHeight: Float = 32
  static let paddleSpeed: Float = 300
  static let ballRadius: Float = 4
  static let ballVelocity: Float = 200
  static let viewW: Float = 320
  static let viewH: Float = 240
}

private let PongActions = Actions {
  ActionRecipes.axisUD(namePrefix: "left_move", device: 0, axis: .leftY, dz: 0.2, keyDown: .s, keyUp: .w, btnDown: .dpadDown, btnUp: .dpadUp)
  ActionRecipes.axisUD(namePrefix: "right_move", device: 1, axis: .leftY, dz: 0.2, keyDown: .down, keyUp: .up, btnDown: .dpadDown, btnUp: .dpadUp)
}
