import ArgumentParser

// Command-line options for the chat sample app.
// Example usage:
// godot --path ./GodotProject/ -- chat --server --port 8989
// godot --path ./GodotProject/ -- chat --client --host 127.0.0.1 --port 8989
struct ChatOpts: ParsableArguments {
  @Flag(name: .customLong("server")) var server = false
  @Flag(name: .customLong("client")) var client = false
  @Option(name: .customLong("host")) var host: String?
  @Option(name: .shortAndLong) var port: Int = 8989
  @Option(name: .customLong("max-peers")) var maxPeers: Int = 32
  @Option(name: .shortAndLong) var name: String?

  mutating func validate() throws {
    if (server ? 1 : 0) + (client ? 1 : 0) != 1 { throw ValidationError("use exactly one of --server or --client") }
    if client && host == nil { throw ValidationError("--client requires --host") }
  }

  static func parseChatCLI() -> ChatNetMode {
    let opts = try! ChatOpts.parse(userArgs())
    if opts.server { return .server(port: Int32(opts.port), maxPeers: Int32(opts.maxPeers)) }
    return .client(host: opts.host!, port: Int32(opts.port))
  }

  private static func userArgs() -> [String] {
    let all = Array(CommandLine.arguments.dropFirst())
    if let dash = all.firstIndex(of: "--") { return Array(all[(dash + 1)...]) }
    return all
  }
}
