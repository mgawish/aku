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
