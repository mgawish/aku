//
//  PublicController.swift
//  App
//
//  Created by Gawish on 04/07/2020.
//

import Vapor
import Leaf

class PublicController: RouteCollection {
    func boot(router: Router) throws {
        router.get(use: indexHandler)
        router.get("/apps", use: postsHandler)
    }
    
    func indexHandler(req: Request) throws -> Future<View> {
        return try req.view().render("index")
    }
    
    func postsHandler(req: Request) throws -> Future<View> {
        return try req.view().render("posts")
    }
    
}
