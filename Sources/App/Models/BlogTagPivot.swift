//
//  BlogTagPivot.swift
//  App
//
//  Created by Gawish on 17/07/2020.
//

import Vapor
import FluentPostgreSQL

final class BlogTagPivot: PostgreSQLUUIDPivot {
    var id: UUID?
    var blogId: Blog.ID
    var tagId: Tag.ID
    
    typealias Left = Blog
    typealias Right = Tag
    static var leftIDKey: LeftIDKey = \.blogId
    static var rightIDKey: RightIDKey = \.tagId
    
    init(_ left: Left, _ right: Right) throws {
        blogId = try left.requireID()
        tagId = try right.requireID()
      }
}

extension BlogTagPivot: Migration {
    static func prepare(on connection: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            
            builder.reference(from: \.blogId, to: \Blog.id, onDelete: .cascade)
            builder.reference(from: \.tagId, to: \Tag.id, onDelete: .cascade)
        }
    }
}

extension BlogTagPivot: ModifiablePivot {}
