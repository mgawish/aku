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
        router.get("posts", use: postsHandler)
        router.get("createPost", use: getCreatePostHandler)
        router.post(Post.self, at: "createPost", use: createPostHandler)
    }
    
    func indexHandler(req: Request) throws -> Future<View> {
        return try req.view().render("index")
    }
    
    func postsHandler(req: Request) throws -> Future<View> {
        return try req.view().render("posts",
                                     PostContext(posts: Post.query(on: req).all()))
    }
    
    func getCreatePostHandler(req: Request) throws -> Future<View> {
        return try req.view().render("createPost")
    }
    
    func createPostHandler(req: Request, post: Post) throws -> Future<View> {
        try post.validate()
        return post.save(on: req).flatMap(to: View.self, {_ in 
            return try self.postsHandler(req: req)
        })
    }
}

struct PostContext: Encodable {
    let posts: Future<[Post]>
}

