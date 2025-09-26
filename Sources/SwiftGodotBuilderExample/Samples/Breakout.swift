import SwiftGodot
import SwiftGodotBuilder
import SwiftGodotPatterns

private typealias Config = BreakoutConfig

// MARK: - Gameplay Nodes

@Godot
final class BOBall: Area2D {
  var velocity = Vector2(260, -260)

  override func _physicsProcess(delta: Double) {
    var p = position
    p.x += velocity.x * Float(delta)
    p.y += velocity.y * Float(delta)

    let s = visibleSize
    let r = Config.ballRadius

    if p.x < r || p.x > s.x - r {
      velocity.x = -velocity.x
      p.x = min(max(p.x, r), s.x - r)
    }
    if p.y < r {
      velocity.y = -velocity.y
      p.y = r
    }
    if p.y > s.y + r {
      resetBall()
      return
    }

    position = p
  }

  func bounceFromBrick() { velocity.y = -velocity.y }

  func bounceFromPaddle(paddleY _: Float) {
    velocity.y = -abs(velocity.y)
    velocity.x += Float.random(in: -40 ... 40)
  }

  func resetBall() {
    position = visibleCenter
    velocity = Vector2(260, -260)
  }
}

@Godot
final class BOBrick: Area2D {}

@Godot
final class BOPaddle: Area2D {
  var speed = 480.0
  private var halfWidth: Float { Config.paddleW / 2 }

  override func _physicsProcess(delta: Double) {
    let right = Input.getActionStrength(action: StringName("pad_right"))
    let left = Input.getActionStrength(action: StringName("pad_left"))
    let dir = right - left
    if dir == 0 { return }

    var x = position.x + Float(speed * dir * delta)
    x = min(max(x, halfWidth), visibleSize.x - halfWidth)
    position.x = x
  }
}

// MARK: - Config

enum BreakoutConfig {
  static let ballRadius: Float = 4
  static let ballVelocity: Float = 200
  static let paddleW: Float = 64
  static let paddleH: Float = 12
  static let paddleMargin: Float = 20
  static let viewW: Float = 320
  static let viewH: Float = 240
  static let brickCols = 5
  static let brickRows = 3
  static let bricksX: Float = 48
  static let bricksY: Float = 16
  static let brickW: Float = 56
  static let brickH: Float = 22
}

// MARK: - Scene

struct BreakoutView: GView {
  init() {
    GodotRegistry.append([BOBall.self, BOBrick.self, BOPaddle.self])
    breakoutActions.install(clearExisting: true)
  }

  var body: some GView {
    Node2D$ {
      // Ball
      GNode<BOBall> {
        Sprite2D$().res(\.texture, "ball.png")
        CollisionShape2D$().shape(CircleShape2D(radius: Double(Config.ballRadius)))
      }
      .position(Vector2(Config.viewW / 2, Config.viewH / 2))
      .on(\.areaEntered) { ball, area in
        guard let area else { return }
        switch area {
        case is BOPaddle: ball.bounceFromPaddle(paddleY: area.position.y)
        case let b as BOBrick: ball.bounceFromBrick()
          b.queueFree()
        default: break
        }
      }

      // Paddle
      GNode<BOPaddle> {
        Sprite2D$()
          .res(\.texture, "bo_paddle.png")
          .modulate(Color(r: 0.9, g: 0.9, b: 1, a: 1))
        CollisionShape2D$().shape(RectangleShape2D(w: Config.paddleW, h: Config.paddleH))
      }
      .position(Vector2(Config.viewW / 2, Config.viewH - Config.paddleMargin))

      Node2D$ {
        (0 ..< Config.brickRows).flatMap { row in
          (0 ..< Config.brickCols).map { col in
            GNode<BOBrick> {
              Sprite2D$().res(\.texture, "bo_brick.png")
              CollisionShape2D$().shape(RectangleShape2D(w: Config.brickW - 6, h: Config.brickH - 6))
            }
            .position(Vector2(
              Config.bricksX + Float(col) * Config.brickW,
              Config.bricksY + Float(row) * Config.brickH
            ))
          }
        }
      }

      Camera2D$().position(Vector2(Config.viewW / 2, Config.viewH / 2))
    }
  }
}

private let breakoutActions = Actions {
  ActionRecipes.axisLR(
    namePrefix: "pad",
    device: 0,
    axis: .leftX,
    dz: 0.25,
    keyLeft: .a,
    keyRight: .d,
    btnLeft: .dpadLeft,
    btnRight: .dpadRight
  )
}
