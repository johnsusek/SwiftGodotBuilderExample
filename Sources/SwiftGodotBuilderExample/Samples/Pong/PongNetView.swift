import Foundation
import SwiftGodot
import SwiftGodotBuilder
import SwiftGodotPatterns

public struct PongModel: Codable {
  public var ballPos: Vector2
  public var ballVel: Vector2
  public var leftY: Float
  public var rightY: Float
  public var leftScore: Int
  public var rightScore: Int

  public static func initial() -> Self {
    .init(ballPos: Vector2(PongConfig.viewW * 0.5, PongConfig.viewH * 0.5),
          ballVel: .zero,
          leftY: PongConfig.viewH * 0.5,
          rightY: PongConfig.viewH * 0.5,
          leftScore: 0,
          rightScore: 0)
  }
}

public enum PongIntent: Codable {
  case paddleMove(side: PongSide, dir: Int) // -1 up, +1 down, 0 stop
  case requestServe(toward: PongSide)
}

public enum PongEvent: Codable {
  case authBall(pos: Vector2, vel: Vector2)
  case authPaddle(side: PongSide, y: Float)
  case served(toward: PongSide, pos: Vector2, vel: Vector2)
}

public enum PongControl { // local app bus -> net
  case input(side: PongSide, up: Bool, down: Bool)
  case serve(PongSide)
}

struct EmptyStruct: Codable {}

func PongNetView(ball: Ref<CharacterBody2D>, left: Ref<CharacterBody2D>, right: Ref<CharacterBody2D>) -> GNode<NetworkStore> {
  let storeBox = Box(Store<EmptyStruct, PongIntent, PongEvent>(state: EmptyStruct())) // Void model; we only use events/acks

  var desiredDir: [PongSide: Int] = [.left: 0, .right: 0] // server: authoritative input state
  var pendingServe: PongSide? = nil
  var syncTime = 0.0, syncHz = 60.0

  return GNode<NetworkStore>("NetworkStore")
    .onReady { net in
      net.wire(to: storeBox.value)

      // Collect inputs arriving at server.
      storeBox.value.use(.init(after: { _, intents, _ in
        guard net.getTree()?.getMultiplayer()?.isServer() == true else { return }
        for intent in intents {
          switch intent {
          case let .paddleMove(side, dir): desiredDir[side] = dir
          case let .requestServe(toward): pendingServe = toward
          }
        }
      }))

      // Apply authoritative events to scene on both peers (+lerp on clients).
      storeBox.value.events.onEach { e in
        switch e {
        case let .authBall(pos, vel):
          guard let ballNode = ball.node else { return }
          let isServer = ballNode.getTree()?.getMultiplayer()?.isServer() == true
          if isServer { ballNode.position = pos; ballNode.velocity = vel }
          else {
            ballNode.position = ballNode.position.lerp(to: pos, weight: 0.35)
            ballNode.velocity = vel
          }
        case let .authPaddle(side, y):
          let node = (side == .left ? left.node : right.node)
          guard let paddle = node else { return }
          paddle.position.y = y
          paddle.velocity = .zero
        case let .served(_, pos, vel):
          guard let ballNode = ball.node else { return }
          ballNode.position = pos
          ballNode.velocity = vel
        }
      }

      // Local control bus -> intents
      GlobalEventBuses.hub(PongControl.self).onEach { event in
        switch event {
        case let .input(side, up, down):
          let dir = (up == down) ? 0 : (down ? +1 : -1)
          net.commit(PongIntent.paddleMove(side: side, dir: dir))
        case let .serve(toward):
          net.commit(PongIntent.requestServe(toward: toward))
        }
      }
    }
    .onPhysicsProcess { net, dt in
      let isServer = net.getTree()?.getMultiplayer()?.isServer() == true

      // Server: move paddles from last received input; trigger serves; broadcast state at Hz.
      if isServer {
        if let serveSide = pendingServe, let ballNode = ball.node {
          pendingServe = nil
          let baseX: Float = (serveSide == .left) ? -1 : 1
          let ang = Float.random(in: -deg2rad(15) ... deg2rad(15))
          let dir = Vector2(baseX, 0).rotated(angle: Double(ang)).normalized()
          ballNode.position = Vector2(PongConfig.viewW * 0.5, PongConfig.viewH * 0.5)
          ballNode.velocity = dir * PongConfig.ballSpeedStart
          net.broadcast([PongEvent.served(toward: serveSide, pos: ballNode.position, vel: ballNode.velocity)])
        }

        // Authoritative paddle motion (server owns truth)
        func stepPaddle(_ side: PongSide, node: CharacterBody2D?) {
          guard let node else { return }
          let dy = Float(dt) * PongConfig.paddleSpeed * Float(desiredDir[side] ?? 0)
          var newY = node.position.y + dy
          let minY = PongConfig.paddleHeight * 0.5, maxY = PongConfig.viewH - minY
          if newY < minY { newY = minY }
          if newY > maxY { newY = maxY }
          node.position.y = newY
        }
        stepPaddle(.left, node: left.node)
        stepPaddle(.right, node: right.node)

        syncTime += dt
        if syncTime < (1.0 / syncHz) { return }
        syncTime = 0

        var out: [PongEvent] = []
        if let ballNode = ball.node { out.append(.authBall(pos: ballNode.position, vel: ballNode.velocity)) }
        if let leftNode = left.node { out.append(.authPaddle(side: .left, y: leftNode.position.y)) }
        if let rightNode = right.node { out.append(.authPaddle(side: .right, y: rightNode.position.y)) }
        if !out.isEmpty { net.broadcast(out) }
      }
    }
}

// Simple box holder for reference types created inside a view function.
final class Box<T> { var value: T; init(_ v: T) { value = v } }
extension Box { convenience init(_ v: @autoclosure () -> T) { self.init(v()) } }

func StartServerButton() -> Button$ {
  Button$()
    .text("Host")
    .on(\.pressed) { btn in
      guard let mpApi = Engine.getSceneTree()?.getMultiplayer() else { return }
      let peer = ENetMultiplayerPeer()
      let res = peer.createServer(port: 2457, maxClients: 8)
      if res != .ok { GD.print("ENet createServer failed:", res); return }
      GD.print("Server started on port 2457")
      mpApi.multiplayerPeer = peer
      btn.visible = false
    }
}

func JoinClientButton(host: String = "127.0.0.1") -> Button$ {
  Button$()
    .text("Join")
    .on(\.pressed) { btn in
      guard let mpApi = Engine.getSceneTree()?.getMultiplayer() else { return }
      let peer = ENetMultiplayerPeer()
      let err = peer.createClient(address: host, port: 2457)
      if err != .ok { GD.print("ENet createClient failed:", err); return }
      GD.print("Connecting to \(host):2457...")
      mpApi.multiplayerPeer = peer
      btn.visible = false
    }
}
