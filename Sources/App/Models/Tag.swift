//
//  Tag.swift
//  App
//
//  Created by Gawish on 17/07/2020.
//

import Vapor
import FluentPostgreSQL

final class Tag: Codable {
    var id: UUID?
    let name: String

    init(name: String) {
        self.name = name
    }
}

extension Tag: PostgreSQLUUIDModel {}
extension Tag: Content {}
extension Tag: Migration {}
extension Tag: Parameter {}
