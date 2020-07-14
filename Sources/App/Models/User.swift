//
//  User.swift
//  App
//
//  Created by Gawish on 04/07/2020.
//

import Vapor
import FluentPostgreSQL
import Crypto
import Authentication

final class User: Codable {
    var id: UUID?
    var name: String
    var password: String
    
    init(name: String, password: String) {
        self.name = name
        self.password = password
    }
}

extension User: PasswordAuthenticatable {
    static var usernameKey: UsernameKey {
        return \.name
    }
    
    static var passwordKey: PasswordKey {
        return \.password
    }
}

extension User: SessionAuthenticatable {}
extension User: PostgreSQLUUIDModel {}
extension User: Content {}
extension User: Migration {}
extension User: Parameter {}

class AdminUser: Migration {
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
