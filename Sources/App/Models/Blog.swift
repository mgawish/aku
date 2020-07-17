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
    var company: String
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
         company: String,
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
        self.company = company
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
                           company: self.company,
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
        self.company = data.company
        self.slug = data.slug
        self.imageUrl = data.imageUrl
        self.thumbUrl = data.thumbUrl
        self.appStoreUrl = data.appStoreUrl
        self.googlePlayUrl = data.googlePlayUrl
        self.githubUrl = data.githubUrl
        self.order = Int(data.order) ?? 0
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

class BlogMigration: Migration {
    static func prepare(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        Database.update(Blog.self, on: conn) { builder in
            builder.field(for: \.company, type: .text, PostgreSQLColumnConstraint.default(._literal("")))
        }
    }
    
    static func revert(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        .done(on: conn)
    }
    
    typealias Database = PostgreSQLDatabase
    
    
}
