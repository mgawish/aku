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
    let userId: User.ID
    let slug: String
    let name: String
    let imageUrl: String
    let content: String
    let order: Int
    let isActive: Bool
}

extension Post: PostgreSQLUUIDModel {}
extension Post: Content {}
extension Post: Migration {}
