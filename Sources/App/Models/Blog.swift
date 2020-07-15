//
//  Post.swift
//  App
//
//  Created by Gawish on 04/07/2020.
//

import Vapor
import FluentPostgreSQL

final class Blog: Codable {
    var id: UUID?
    var name: String
    var content: String
    //let userId: User.ID?
    var slug: String
    var imageUrl: String
    var thumbUrl: String
    var appStoreUrl: String
    var googlePlayUrl: String
    var githubUrl: String
    var order: Int
    var isActive: Bool
    
    init(name: String,
         content: String,
         slug: String,
         imageUrl: String,
         thumbUrl: String,
         appStoreLink: String,
         googlePlayLink: String,
         githubLink: String,
         order: Int,
         isActive: Bool) {
        self.name = name
        self.content = content
        self.slug = slug
        self.imageUrl = imageUrl
        self.thumbUrl = thumbUrl
        self.appStoreUrl = appStoreLink
        self.googlePlayUrl = googlePlayLink
        self.githubUrl = githubLink
        self.order = order
        self.isActive = isActive
    }
    
    func convertToContext() -> BlogContext {
        return BlogContext(id: self.id,
                           name: self.name,
                           content: self.content,
                           slug: self.slug,
                           imageUrl: self.imageUrl,
                           thumbUrl: self.thumbUrl,
                           appStoreUrl: self.appStoreUrl,
                           googlePlayUrl: self.googlePlayUrl,
                           githubUrl: self.githubUrl,
                           order: String(self.order),
                           isActive: self.isActive ? "checked" : "")
    }
    
    func update(_ data: BlogContext) {
        self.name = data.name
        self.content = data.content
        self.slug = data.slug
        self.imageUrl = data.imageUrl
        self.thumbUrl = data.thumbUrl
        self.appStoreUrl = data.appStoreUrl
        self.googlePlayUrl = data.googlePlayUrl
        self.githubUrl = data.githubUrl
        self.order = Int(data.order) ?? 0
        self.content = data.content
        self.isActive = data.isActive == "on"
    }
}

extension Blog: PostgreSQLUUIDModel {}
extension Blog: Content {}
extension Blog: Parameter {}

extension Blog: Migration {
    }

extension Blog: Validatable, Reflectable {
    static func validations() throws -> Validations<Blog> {
        var validations = Validations(Blog.self)
        try validations.add(\.name, .count(3...))
        return validations
    }
}

struct NewBlogFields: Migration {
    typealias Database = PostgreSQLDatabase

    static func prepare(on conn: Database.Connection) -> EventLoopFuture<Void> {
        return Database.update(Blog.self, on: conn) { builder in
            builder.field(for: \.thumbUrl, type: .text, PostgreSQLColumnConstraint.default(.literal("")))
            builder.field(for: \.appStoreUrl, type: .text, PostgreSQLColumnConstraint.default(.literal("")))
            builder.field(for: \.googlePlayUrl, type: .text, PostgreSQLColumnConstraint.default(.literal("")))
            builder.field(for: \.githubUrl, type: .text, PostgreSQLColumnConstraint.default(.literal("")))
        }
    }
    
    static func revert(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return .done(on: conn)
    }
}

struct NewBlogFields2: Migration {
    typealias Database = PostgreSQLDatabase

    static func prepare(on conn: Database.Connection) -> EventLoopFuture<Void> {
        return Database.update(Blog.self, on: conn) { builder in
            builder.field(for: \.appStoreUrl, type: .text, PostgreSQLColumnConstraint.default(.literal("")))
            builder.field(for: \.googlePlayUrl, type: .text, PostgreSQLColumnConstraint.default(.literal("")))
            builder.field(for: \.githubUrl, type: .text, PostgreSQLColumnConstraint.default(.literal("")))
        }
    }
    
    static func revert(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return .done(on: conn)
    }
}
