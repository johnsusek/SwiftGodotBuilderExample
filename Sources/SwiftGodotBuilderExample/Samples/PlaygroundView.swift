import SwiftGodot
import SwiftGodotBuilder

//let towns = HFlowContainer$ {
//  ["Longideer", "Gryynwych", "Exclusitor", "Pinebruim"]
//    .map { Button$().text($0) }
//}
//.anchors(.topWide)
//.offset(top: 54, left: 10)
//
//let inventory = HBoxContainer$ {
//  ["🗡️", "🛡️", "💣", "🧪", "🪄"]
//    .map { Button$().text($0) }
//}
//.anchors(.topWide)
//.offset(top: 10, right: -10)
//.alignment(.end)
//
//let lucre = Label$().text("¤ 42")
//  .modulate(Color(code: "#EE1"))
//  .anchors(.topLeft)
//  .offsets(.topLeft, margin: 10)
//
//let health = Label$().text("9 ❤️")
//  .modulate(Color(code: "#F00"))
//  .anchors(.bottomLeft)
//  .offsets(.bottomLeft, margin: 10)


let overlay = Panel$ {
  CenterContainer$ {
    VBoxContainer$ {
      Label$().text("Mycolony")
      Button$().text("Start").on(\.pressed) { _ in
      }
    }
    .alignment(.center)
  }
}
.visible(true)

struct PlaygroundView: GView {
  var body: some GView {
    CanvasLayer$ {
      
      overlay
    }
  }
}
