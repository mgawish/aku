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
    var tags: Siblings<Blog, Tag, BlogTagPivot> {
        return siblings()
    }
    
    init(_ data: BlogContext) {
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
    
    func update(_ data: BlogContext, req: Request) throws -> Future<Blog> {
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
        return try updateBlogTags(data.tags, req: req).transform(to: self)
    }
    
    private func copyValues(data: BlogContext) {
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
    
    func updateBlogTags(_ responseTags: [String], req: Request) throws -> Future<Blog> {
        return flatMap(to: Blog.self,
                try self.tags.query(on: req).all(),
                Tag.query(on: req).all()) { blogTags, allTags in
                    var actions = [Future<Void>]()
                    
                    //remove tags
                    actions = blogTags.compactMap({ tag in
                        if !responseTags.contains(where: {$0 == tag.name}) {
                            return self.tags.detach(tag, on: req)
                        } else {
                            return nil
                        }
                    })
                    
                    //add tags
                    actions += responseTags.compactMap({ tagName in
                        if blogTags.contains(where: { $0.name == tagName}) {
                            return nil
                        }
                        if let tag = allTags.filter({ $0.name == tagName }).first {
                            return self.tags.attach(tag, on: req).transform(to: ())
                        } else {
                            return Tag(name: tagName).save(on: req).flatMap(to: Void.self) { tag in
                                self.tags.attach(tag, on: req).transform(to: ())
                            }
                        }
                    })
                    
                    return actions.flatten(on: req).transform(to: self)
        }
    }
    
    func convertToContext(req: Request) throws -> Future<BlogContext> {
        map(to: BlogContext.self,
            try self.tags.query(on: req).all(),
            Tag.query(on: req).all(), { tags, allTags in
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
                                   isActive: self.isActive ? "checked" : "",
                                   tags: tags.map({ $0.name }),
                                   allTags: allTags.map({ $0.name }))
                
        })
    }
}

extension Blog: PostgreSQLUUIDModel {}
extension Blog: Content {}
extension Blog: Parameter {}
extension Blog: Migration {}

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
