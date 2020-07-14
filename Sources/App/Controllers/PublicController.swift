//
//  PublicController.swift
//  App
//
//  Created by Gawish on 04/07/2020.
//

import Vapor
import Leaf
import Crypto
import Fluent
import Authentication

class PublicController: RouteCollection {
    func boot(router: Router) throws {
        router.get(use: indexViewHandler)
        router.get("apps", use: blogsViewHandler)
        router.get("apps", Blog.parameter, use: blogDetailsViewHanlder)
        router.get("login", use: loginViewHandler)
        router.post(LoginData.self, at: "login", use: loginHandler)
        
        let adminRoutes = router.grouped([User.authSessionsMiddleware(),
                                          RedirectMiddleware<User>(path: "/login")])
        
        adminRoutes.get("admin", use: adminBlogsViewHandler)
        adminRoutes.get("admin", "apps", use: adminBlogsViewHandler)
        adminRoutes.get("admin", "users", use: adminUsersViewHandler)

        adminRoutes.get("admin", "apps", "create", use: createBlogViewHandler)
        adminRoutes.post(BlogContext.self, at: "admin", "apps", "create", use: createBlogHandler)
        adminRoutes.get("admin", "apps", Blog.parameter, use: editBlogViewHandler)
        adminRoutes.post(BlogContext.self, at: "admin", "apps", Blog.parameter, "edit", use: editBlogHandler)
        adminRoutes.post( "admin", "apps", Blog.parameter, "delete", use: deleteBlogHandler)
        
        adminRoutes.get("admin", "users", "create", use: createUserViewHandler)
        adminRoutes.post(UserContext.self, at: "admin", "users", "create", use: createUserHandler)
        adminRoutes.get("admin", "users", User.parameter, use: editUserViewHandler)
        adminRoutes.post(UserContext.self, at: "admin", "users", User.parameter, "edit", use: editUserHandler)
    }
    
    //MARK:- Public
    func indexViewHandler(req: Request) throws -> Future<View> {
        let blogs = Blog
            .query(on: req)
            .filter(\.isActive == true)
            .sort(\.order)
            .all()
        return try req.view().render("index",
                                     BlogsContext(blogs: blogs))
    }
    
    func blogsViewHandler(req: Request) throws -> Future<View> {
        return try req.view().render("blogs",
                                     BlogsContext(blogs: Blog.query(on: req).all()))
    }
    
    func blogDetailsViewHanlder(req: Request) throws -> Future<View> {
        return try req.parameters.next(Blog.self).flatMap(to: View.self) { blog in
            return try req.view().render("blogDetails", blog.convertToContext())
        }
    }
    
    //MARK:- Admin Blogs
    func adminBlogsViewHandler(req: Request) throws -> Future<View> {
        _ = try req.requireAuthenticated(User.self)
        return try req.view().render("adminBlogs",
                                     BlogsContext(blogs: Blog.query(on: req).all()))
    }
    
    func createBlogViewHandler(req: Request) throws -> Future<View> {
        _ = try req.requireAuthenticated(User.self)
        return try req.view().render("adminModifyBlog")
    }
    
    func createBlogHandler(req: Request, data: BlogContext) throws -> Future<View> {
        _ = try req.requireAuthenticated(User.self)
        let blog = Blog(name: data.name,
                        content: data.content,
                        slug: data.slug,
                        imageUrl: data.imageUrl,
                        order: Int(data.order) ?? 0,
                        isActive: data.isActive == "on")
        return blog.save(on: req).flatMap(to: View.self, {_ in
            return try self.adminBlogsViewHandler(req: req)
        })
    }
    
    func editBlogViewHandler(req: Request) throws -> Future<View> {
        _ = try req.requireAuthenticated(User.self)
        return try req.parameters.next(Blog.self).flatMap(to: View.self) { blog in
            let context = BlogContext(id: blog.id,
                                      name: blog.name,
                                      content: blog.content,
                                      slug: blog.slug,
                                      imageUrl: blog.imageUrl,
                                      order: String(blog.order),
                                      isActive: blog.isActive ? "on" : "")
            return try req.view().render("adminModifyBlog", context)
        }
    }
    
    func editBlogHandler(req: Request, data: BlogContext) throws -> Future<View> {
        _ = try req.requireAuthenticated(User.self)
        try data.validate()
        return try req.parameters.next(Blog.self).flatMap(to: View.self, { blog in
            blog.name = data.name
            blog.content = data.content
            blog.slug = data.slug
            blog.imageUrl = data.imageUrl
            blog.order = Int(data.order) ?? 0
            blog.content = data.content
            blog.isActive = data.isActive == "on"
            
            return blog.save(on: req).flatMap(to: View.self, { _ in
                return try self.adminBlogsViewHandler(req: req)
            })
        })
    }
    
    func deleteBlogHandler(req: Request) throws -> Future<View> {
        _ = try req.requireAuthenticated(User.self)
        return try req.parameters.next(Blog.self).delete(on: req).flatMap(to: View.self, { blog in
            return try self.adminBlogsViewHandler(req: req)
        })
    }
    
    //MARK:- Admin Users
    func adminUsersViewHandler(req: Request) throws -> Future<View> {
        _ = try req.requireAuthenticated(User.self)
        return try req.view().render("adminUsers",
                                     UsersContext(users: User.query(on: req).all()))
    }
    
    func createUserViewHandler(req: Request) throws -> Future<View> {
        _ = try req.requireAuthenticated(User.self)
        return try req.view().render("adminModifyUser")
    }
    
    func createUserHandler(req: Request, data: UserContext) throws -> Future<View> {
        _ = try req.requireAuthenticated(User.self)
        try data.validate()
        let password = try BCrypt.hash(data.password)
        let user = User(name: data.name , password: password)
        return user.save(on: req).flatMap(to: View.self, {_ in
            return try self.adminUsersViewHandler(req: req)
        })
    }
    
    func editUserViewHandler(req: Request) throws -> Future<View> {
        _ = try req.requireAuthenticated(User.self)
        return try req.parameters.next(User.self).flatMap(to: View.self) { user in
            return try req.view().render("adminModifyUser", user)
        }
    }
    
    func editUserHandler(req: Request, data: UserContext) throws -> Future<View> {
        _ = try req.requireAuthenticated(User.self)
        try data.validate()
        return try req.parameters.next(User.self).flatMap(to: View.self, { user in
            user.name = data.name
            user.password = try BCrypt.hash(data.password)
            return user.save(on: req).flatMap(to: View.self, { _ in
                return try self.adminUsersViewHandler(req: req)
            })
        })
    }
    
    //MARK:- Login
    func loginViewHandler(req: Request) throws -> Future<View> {
        return try req.view().render("login")
    }
    
    func loginHandler(req: Request, data: LoginData) throws -> Future<Response> {
        return User.authenticate(username: data.username,
                                 password: data.password,
                                 using: BCryptDigest(),
                                 on: req).map(to: Response.self, { user in
                                    guard let user = user else {
                                        return req.redirect(to: "/login?error")
                                    }
                                    
                                    try req.authenticateSession(user)
                                    return req.redirect(to: "/admin")
                                 })
    }
}

struct BlogsContext: Encodable {
    let blogs: Future<[Blog]>
}

struct UsersContext: Encodable {
    let users: Future<[User]>
}

struct UserContext: Content, Validatable, Reflectable {
    let name: String
    let password: String
    let confirmPassword: String
    
    static func validations() throws -> Validations<UserContext> {
        var validations = Validations(UserContext.self)
        try validations.add(\.name, .count(3...))
        try validations.add(\.password, .count(3...))
        validations.add("confirm password", { context in
            if context.password != context.confirmPassword {
                throw BasicValidationError("Passwords don’t match")
            }
        })
        return validations
    }
}

struct BlogContext: Content, Validatable, Reflectable {
    var id: UUID?
    let name: String
    let content: String
    let slug: String
    let imageUrl: String
    let order: String
    let isActive: String?
    let error: String? = nil
    
    static func validations() throws -> Validations<BlogContext> {
        var validations = Validations(BlogContext.self)
        try validations.add(\.name, .count(3...))
        try validations.add(\.slug, .count(3...))
        return validations
    }
}

struct LoginData: Content, Validatable, Reflectable {
    let username: String
    let password: String
    
    static func validations() throws -> Validations<LoginData> {
        var validations = Validations(LoginData.self)
        try validations.add(\.username, .count(3...))
        try validations.add(\.password, .count(3...))
        return validations
    }
}
