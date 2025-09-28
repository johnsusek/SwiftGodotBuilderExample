import SwiftGodot
import SwiftGodotBuilder
import SwiftGodotPatterns

struct PongView: GView {
  let ballRef = Ref<CharacterBody2D>()

  init() {
    for t in [GProcessRelay.self] {
      register(type: t)
    }
    PongActions.install()
  }

  var body: some GView {
    Node2D$("GameRoot") {
      PongWallView()
        .position(Vector2(PongConfig.viewW * 0.5, 0))

      PongWallView()
        .position(Vector2(PongConfig.viewW * 0.5, PongConfig.viewH))

      PongGoalView()
        .position(Vector2(-8, PongConfig.viewH * 0.5))
        .on(\.bodyEntered) { _, _ in
          serveBall(ballRef.node, toward: .right)
        }

      PongGoalView()
        .position(Vector2(PongConfig.viewW + 8, PongConfig.viewH * 0.5))
        .on(\.bodyEntered) { _, _ in
          serveBall(ballRef.node, toward: .left)
        }

      PongBallView().ref(ballRef)

      PongPaddleView(side: .left)
        .position(Vector2(PongConfig.paddleWidth + 8, PongConfig.viewH * 0.5))

      PongPaddleView(side: .right)
        .position(Vector2(PongConfig.viewW - PongConfig.paddleWidth - 8, PongConfig.viewH * 0.5))
    }
    .onKey(.r, when: [.pressed], scope: .unhandled) { _, _ in
      serveBall(ballRef.node, toward: Bool.random() ? .left : .right)
    }
  }
}
