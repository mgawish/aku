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
    //let order: Int?
    //let isActive: Bool?
}

extension Blog: PostgreSQLUUIDModel {}
extension Blog: Content {}
extension Blog: Migration {}
extension Blog: Parameter {}

extension Blog: Validatable, Reflectable {
    static func validations() throws -> Validations<Blog> {
        var validations = Validations(Blog.self)
        try validations.add(\.name, .count(3...))
        return validations
    }
}
