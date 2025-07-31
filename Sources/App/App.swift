import ArgumentParser
import Hummingbird
import Logging

@main
struct AppCommand: AsyncParsableCommand, AppArguments {
    @Option(name: .shortAndLong, help: "Hostname to bind server to")
    var hostname: String = "127.0.0.1"

    @Option(name: .shortAndLong, help: "Port to run server on")
    var port: Int = 8080

    @Option(name: .shortAndLong, help: "Log level (eg. info, debug, error)")
    var logLevel: Logger.Level?

    @Flag(name: .shortAndLong, help: "Run Fluent database migrations")
    var migrate: Bool = false

    @Flag(name: .shortAndLong, help: "Revert Fluent database migrations")
    var revert: Bool = false

    func run() async throws {
        let app = try await buildApplication(self)
        try await app.runService()
    }
}

#if hasFeature(RetroactiveAttribute)
    extension Logger.Level: @retroactive ExpressibleByArgument {}
#else
    extension Logger.Level: ExpressibleByArgument {}
#endif
