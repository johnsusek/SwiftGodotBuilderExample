import SwiftGodot
import SwiftGodotBuilder

func initHook(level: GDExtension.InitializationLevel) {
  // If this message never appears, but you don't see any GDExtension errors,
  // try to delete your .build/ folder.
  GD.print("[SwiftGodot] initHook called with level \(level.rawValue)")

  if level == .scene {
    register(type: GameRoot.self)
  }
}

@_cdecl("swift_entry_point")
public func swift_entry_point(
  interfacePtr: OpaquePointer?,
  libraryPtr: OpaquePointer?,
  extensionPtr: OpaquePointer?
) -> UInt8 {
  guard let interfacePtr, let libraryPtr, let extensionPtr else { return 0 }
  initializeSwiftModule(interfacePtr, libraryPtr, extensionPtr, initHook: initHook, deInitHook: { _ in })
  return 1
}
