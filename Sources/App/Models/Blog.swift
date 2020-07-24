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
    
    init(_ data: Blog.Data) {
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
}
//MARK:- Tags
extension Blog {
    var tags: Siblings<Blog, Tag, BlogTagPivot> {
        return siblings()
    }
}

//MARK:- Content
extension Blog {
    struct Data: Content, Validatable, Reflectable {
        var username: String? = nil
        var id: UUID?
        let name: String
        let content: String
        let company: String
        let slug: String
        let imageUrl: String
        let thumbUrl: String
        let appStoreUrl: String
        let googlePlayUrl: String
        let githubUrl: String
        let order: String
        let isActive: String?
        let error: String? = nil
        var tags: [String]
        var allTags: [String]
        
        static func validations() throws -> Validations<Data> {
            var validations = Validations(Data.self)
            try validations.add(\.name, .count(3...))
            try validations.add(\.slug, .count(3...))
            return validations
        }
    }
    
    func update(_ data: Blog.Data, req: Request) throws -> Future<Blog> {
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
    
    private func copyValues(data: Blog.Data) {
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
    
    func convertToData(req: Request) throws -> Future<Blog.Data> {
        map(to: Blog.Data.self,
            try self.tags.query(on: req).all(),
            Tag.query(on: req).all(), { tags, allTags in
                return Blog.Data(id: self.id,
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

//MARK:- Params
extension Blog: Parameter {
    static func resolveParameter(_ parameter: String, on container: Container) throws -> EventLoopFuture<Blog> {
        if let id = UUID(parameter) {
            return container.requestCachedConnection(to: .psql).flatMap(to: Blog.self, { req in
                return Blog.query(on: req)
                    .filter(\.id == id)
                    .first()
                    .unwrap(or: Abort(.notFound))
                    .always {
                        try? container.releasePooledConnection(req, to: .psql)
                    }
            })
        }
        
        return container.requestCachedConnection(to: .psql).flatMap(to: Blog.self, { req in
            return Blog.query(on: req)
                .filter(\.slug == parameter)
                .first()
                .unwrap(or: Abort(.notFound))
                .always {
                    try? container.releasePooledConnection(req, to: .psql)
                }
        })
    }
}
//NARK:- Validation
extension Blog: Validatable, Reflectable {
    static func validations() throws -> Validations<Blog> {
        var validations = Validations(Blog.self)
        try validations.add(\.name, .count(3...))
        return validations
    }
}

//MARK:- Default Protocols
extension Blog: PostgreSQLUUIDModel {}
extension Blog: Content {}
extension Blog: Migration {}


