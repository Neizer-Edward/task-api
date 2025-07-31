import FluentPostgresDriver
import Hummingbird
import HummingbirdAuth
import HummingbirdFluent
import HummingbirdBasicAuth
import JWTKit
import Logging

public protocol AppArguments {
    var hostname: String { get }
    var port: Int { get }
    var logLevel: Logger.Level? { get }
    var migrate: Bool { get }
    var revert: Bool { get }
}

typealias AppRequestContext = BasicAuthRequestContext<User>

func buildApplication(_ arguments: some AppArguments) async throws -> some ApplicationProtocol {
    
    var logger = Logger(label: "SwiftTaskAPI")
    if let level = arguments.logLevel {
        logger.logLevel = level
    }

    let fluent = Fluent(logger: logger)
    fluent.databases.use(
        .postgres(
            configuration: .init(
                hostname: "localhost",
                username: "nyzer",
                password: "nyzer",
                database: "taskdb",
                tls: .disable
            )
        ),
        as: .psql
    )

    await fluent.migrations.add(CreateUser())
    await fluent.migrations.add(CreateShop())
    await fluent.migrations.add(AddShopIDToUser())
    await fluent.migrations.add(CreateProduct())
    await fluent.migrations.add(CreateSale())
    await fluent.migrations.add(CreateSaleItem())

    let fluentPersist = await FluentPersistDriver(fluent: fluent)

    if arguments.revert {
        try await fluent.revert()
    }
    if arguments.migrate {
        try await fluent.migrate()
    }

    let jwtKeyCollection = JWTKeyCollection()
    let kid = JWKIdentifier("auth-jwt")
    await jwtKeyCollection.add(hmac: "my-secret-key", digestAlgorithm: .sha256, kid: kid)

    let router = Router(context: AppRequestContext.self)
    router.add(middleware: LogRequestsMiddleware(arguments.logLevel ?? .info))

    router.get("/health") { _, _ in HTTPResponse.Status.ok }

    router.get("/hello") { request, context in
        return "Hello"
    }

    let authGroup = router.group("auth")
    UserController(
        jwtKeyCollection: jwtKeyCollection,
        kid: kid,
        fluent: fluent
    ).addRoutes(to: authGroup)

    authGroup
        .group()
        .add(middleware: JWTAuthenticator(jwtKeyCollection: jwtKeyCollection, fluent: fluent))
        .get("me") { _, context in
            guard let user = context.identity else { throw HTTPError(.unauthorized) }
            return UserResponse(from: user)
        }

    let protectedAPI = router
        .group("api")
        .add(middleware: JWTAuthenticator(jwtKeyCollection: jwtKeyCollection, fluent: fluent))

    protectedAPI.get("dashboard") { _, context in
        guard let user = context.identity else { throw HTTPError(.unauthorized) }
        return ["message": "Hello, \(user.name). You are viewing the dashboard."]
    }

    let shopController = ShopController(
        fluent: fluent,
        jwtKeyCollection: jwtKeyCollection,
        kid: kid
    )
    shopController.addRoutes(to: router.group())

    let productController = ProductController(
    fluent: fluent,
    jwtKeyCollection: jwtKeyCollection,
    kid: kid
    )
    productController.addRoutes(to: protectedAPI)

    let saleController = SaleController(
    fluent: fluent,
    jwtKeyCollection: jwtKeyCollection,
    kid: kid
)
    saleController.addRoutes(to: protectedAPI)
            
        var app = Application(
            router: router,
            configuration: .init(address: .hostname(arguments.hostname, port: arguments.port)),
            logger: logger
        )

    app.addServices(fluent, fluentPersist)
    return app
}
