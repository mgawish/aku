import FluentPostgreSQL
import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    // Register providers first
    try services.register(FluentPostgreSQLProvider())

    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    // Register middleware
    var middlewares = MiddlewareConfig()
    middlewares.use(ErrorMiddleware.self)
    services.register(middlewares)

    // Configure DB
    let databaseConfig: PostgreSQLDatabaseConfig
    if let url = Environment.get("DATABASE_URL") {
        databaseConfig = PostgreSQLDatabaseConfig(url: url)!
    } else if env == .testing {
        databaseConfig = PostgreSQLDatabaseConfig(hostname: "localhost",
                                                  port: 5433,
                                                  username: "aku-test",
                                                  database: "aku-test",
                                                  password: "password")
    } else {
        databaseConfig = PostgreSQLDatabaseConfig(hostname: "localhost",
                                                  port: 5432,
                                                  username: "aku",
                                                  database: "aku",
                                                  password: "password")
    }

    // Register the configured SQLite database to the database config.
    let database = PostgreSQLDatabase(config: databaseConfig)
    var databases = DatabasesConfig()
    databases.add(database: database, as: .psql)
    services.register(databases)

    // Configure migrations
    var migrations = MigrationConfig()
    services.register(migrations)
}
