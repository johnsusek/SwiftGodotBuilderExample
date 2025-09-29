import SwiftGodot
import SwiftGodotBuilder
import SwiftGodotPatterns

struct PongView: GView {
  let ballRef = Ref<CharacterBody2D>()
  let leftRef = Ref<CharacterBody2D>()
  let rightRef = Ref<CharacterBody2D>()

  init() {
    for t in [GProcessRelay.self, NetworkStore.self] {
      register(type: t)
    }
    PongActions.install()
  }

  var body: some GView {
    Node2D$("GameRoot") {
      CanvasLayer$ {
        HBoxContainer$ {
          StartServerButton()
          JoinClientButton()
        }
      }

      PongNetView(ball: ballRef, left: leftRef, right: rightRef)

      PongWallView()
        .position(Vector2(PongConfig.viewW * 0.5, 0))

      PongWallView()
        .position(Vector2(PongConfig.viewW * 0.5, PongConfig.viewH))

      PongGoalView(side: .left)
        .position(Vector2(-8, PongConfig.viewH * 0.5))
      PongGoalView(side: .right)
        .position(Vector2(PongConfig.viewW + 8, PongConfig.viewH * 0.5))

      PongBallView().ref(ballRef)

      PongPaddleView(side: .left)
        .position(Vector2(PongConfig.paddleWidth + 8, PongConfig.viewH * 0.5))
        .ref(leftRef)

      PongPaddleView(side: .right)
        .position(Vector2(PongConfig.viewW - PongConfig.paddleWidth - 8, PongConfig.viewH * 0.5))
        .ref(rightRef)
    }
    .onKey(.r, when: [.pressed], scope: .unhandled) { _, _ in
      serveBall(ballRef.node, toward: Bool.random() ? .left : .right)
    }
  }
}
