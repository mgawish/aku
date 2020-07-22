//
//  AdminUserMigration.swift
//  App
//
//  Created by Gawish on 22/07/2020.
//

import Vapor
import FluentPostgreSQL
import Authentication

class AdminUserMigration: Migration {
    static func prepare(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        let password = try? BCrypt.hash("password")
        let admin = User(name: "admin", password: password ?? "password")
        return admin.save(on: conn).transform(to: ())
    }
    
    static func revert(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return .done(on: conn)
    }
    
    typealias Database = PostgreSQLDatabase
}
