//
//  BlogMigration.swift
//  App
//
//  Created by Gawish on 22/07/2020.
//

import Vapor
import FluentPostgreSQL

struct BlogMigration: Migration {
    static func prepare(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        Database.update(Blog.self, on: conn) { builder in
            builder.field(for: \.company, type: .text, PostgreSQLColumnConstraint.default(._literal("")))
            builder.unique(on: \.slug)
        }
    }
    
    static func revert(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        .done(on: conn)
    }
    
    typealias Database = PostgreSQLDatabase
}

struct UniqueSlugMigration: Migration {
    static func prepare(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        Database.update(Blog.self, on: conn) { builder in
            builder.unique(on: \.slug)
        }
    }
    
    static func revert(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        .done(on: conn)
    }
    
    typealias Database = PostgreSQLDatabase
}
