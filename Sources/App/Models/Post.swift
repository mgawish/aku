//
//  Post.swift
//  App
//
//  Created by Gawish on 04/07/2020.
//

import Vapor
import FluentPostgreSQL

final class Post: Codable {
    var id: UUID?
    let name: String
    let content: String
    //let userId: User.ID?
    let slug: String
    let imageUrl: String
    //let order: Int?
    //let isActive: Bool?
    
}

extension Post: PostgreSQLUUIDModel {}
extension Post: Content {}
extension Post: Migration {}

extension Post: Validatable, Reflectable {
    static func validations() throws -> Validations<Post> {
        var validations = Validations(Post.self)
        try validations.add(\.name, .count(3...))
        return validations
        
    }
    
    
}
