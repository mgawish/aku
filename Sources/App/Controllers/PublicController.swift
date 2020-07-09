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
        router.get(use: indexViewHandler)
        router.get("apps", use: blogsViewHandler)
        
        router.get("admin", use: adminBlogsViewHandler)
        router.get("admin", "apps", use: adminBlogsViewHandler)
        router.get("admin", "users", use: adminUsersViewHandler)

        router.get("admin", "apps", "create", use: createBlogViewHandler)
        router.post(Blog.self, at: "admin", "apps", "create", use: createBlogHandler)
        router.get("admin", "apps", Blog.parameter, use: editBlogViewHandler)
        router.post(Blog.self, at: "admin", "apps", Blog.parameter, "edit", use: editBlogHandler)

        
        router.get("admin", "users", use: adminUsersViewHandler)
        
        //router.put("admin", "posts", "update", Post.parameter, use: upatePostHandler)
    }
    
    //MARK:- Public
    func indexViewHandler(req: Request) throws -> Future<View> {
        return try req.view().render("index")
    }
    
    func blogsViewHandler(req: Request) throws -> Future<View> {
        return try req.view().render("blogs",
                                     BlogsContext(blogs: Blog.query(on: req).all()))
    }
    
    //MARK:- Admin
    func adminBlogsViewHandler(req: Request) throws -> Future<View> {
        return try req.view().render("adminBlogs",
                                     BlogsContext(blogs: Blog.query(on: req).all()))
    }
    
    func adminUsersViewHandler(req: Request) throws -> Future<View> {
        return try req.view().render("adminUsers",
                                     UsersContext(users: User.query(on: req).all()))
    }
    
    func createBlogViewHandler(req: Request) throws -> Future<View> {
        return try req.view().render("adminModifyBlog")
    }
    
    func createBlogHandler(req: Request, blog: Blog) throws -> Future<View> {
        try blog.validate()
        return blog.save(on: req).flatMap(to: View.self, {_ in
            return try self.adminBlogsViewHandler(req: req)
        })
    }
    
    func editBlogViewHandler(req: Request) throws -> Future<View> {
        //return try req.view().render("adminModifyBlog")
        return try req.parameters.next(Blog.self).flatMap(to: View.self) { blog in
            return try req.view().render("adminModifyBlog", blog)
        }
    }
    
    func editBlogHandler(req: Request, data: Blog) throws -> Future<View> {
        try data.validate()
        return try req.parameters.next(Blog.self).flatMap(to: View.self, { blog in
            blog.name = data.name
            blog.slug = data.slug
            blog.content = data.content
            blog.imageUrl = data.imageUrl
            return blog.save(on: req).flatMap(to: View.self, { _ in
                return try self.adminBlogsViewHandler(req: req)
            })
        })
    }
    
    
}

struct BlogsContext: Encodable {
    let blogs: Future<[Blog]>
}

struct UsersContext: Encodable {
    let users: Future<[User]>
}
