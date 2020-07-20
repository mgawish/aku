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
        router.get("apps", Blog.parameter, use: blogDetailsViewHanlder)
        router.get("login", use: loginViewHandler)
        router.post(LoginData.self, at: "login", use: loginHandler)
        router.get("logout", use: logoutHandler)
        
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
        
        adminRoutes.get("admin", "tags", use: adminTagsViewHandler)
    }
    
    //MARK:- Public
    func indexViewHandler(req: Request) throws -> Future<View> {
        Blog.query(on: req)
            .filter(\.isActive == true)
            .sort(\.order)
            .all()
            .flatMap(to: View.self, { blogs in
                let data = try blogs.map({ try $0.convertToContext(req: req)}).flatten(on: req)
                return try req.view().render("index", BlogsContext(blogs: data))
            })
    }
    
    func blogDetailsViewHanlder(req: Request) throws -> Future<View> {
        return try req.parameters.next(Blog.self).flatMap(to: View.self) { blog in
            return try req.view().render("blogDetails", blog.convertToContext(req: req))
        }
    }
    
    //MARK:- Admin Blogs
    func adminBlogsViewHandler(req: Request) throws -> Future<View> {
        _  = try req.requireAuthenticated(User.self)
        return Blog
            .query(on: req)
            .filter(\.isActive == true)
            .sort(\.order)
            .all()
            .flatMap(to: View.self, { blogs in
                let data = try blogs.map({ try $0.convertToContext(req: req)}).flatten(on: req)
                return try req.view().render("adminBlogs", BlogsContext(blogs: data))
            })
    }
    
    func createBlogViewHandler(req: Request) throws -> Future<View> {
        _ = try req.requireAuthenticated(User.self)
        return try req.view().render("adminModifyBlog")
    }
    
    func createBlogHandler(req: Request, data: BlogContext) throws -> Future<View> {
        _ = try req.requireAuthenticated(User.self)
        let blog = Blog(data)
        return try blog
            .save(on: req).flatMap(to: Blog.self, { blog in
                return try blog.updateBlogTags(data.tags, req: req)
            })
            .flatMap(to: View.self, {_ in
                return try self.adminBlogsViewHandler(req: req)
        })
    }
    
    func editBlogViewHandler(req: Request) throws -> Future<View> {
        _ = try req.requireAuthenticated(User.self)
        return try req.parameters.next(Blog.self).flatMap(to: View.self) { blog in
            return try req.view().render("adminModifyBlog", blog.convertToContext(req: req))
        }
    }
    
    func editBlogHandler(req: Request, data: BlogContext) throws -> Future<View> {
        _ = try req.requireAuthenticated(User.self)
        try data.validate()
        return try req.parameters.next(Blog.self).flatMap(to: View.self, { blog in
            return try blog.update(data, req: req)
                .save(on: req)
                .flatMap(to: View.self, { _ in
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
        let user = User(name: data.username , password: password)
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
            user.name = data.username
            user.password = try BCrypt.hash(data.password)
            return user.save(on: req).flatMap(to: View.self, { _ in
                return try self.adminUsersViewHandler(req: req)
            })
        })
    }
    
    //MARK:- Tags
    func adminTagsViewHandler(req: Request) throws -> Future<View> {
        return try req.view().render("adminTags", TagsContent(tags: Tag.query(on: req).all()))
    }
    
    //MARK:- Login
    func loginViewHandler(req: Request) throws -> Future<View> {
        let error = req.query[String.self, at: "error"]
        return try req.view().render("login", ErrorContext(error: error))
    }
    
    func loginHandler(req: Request, data: LoginData) throws -> Future<Response> {
        do {
            try data.validate()
        } catch {
            return req.future(req.redirect(to: "/login?error=\(error.localizedDescription.urlEndcoded())"))
        }
        return User.authenticate(username: data.username,
                                 password: data.password,
                                 using: BCryptDigest(),
                                 on: req).map(to: Response.self, { user in
                                    guard let user = user else {
                                        let error = "The username or password you entered are incorrect"
                                        return req.redirect(to: "/login?error=\(error.urlEndcoded())")
                                    }
                                    try req.authenticateSession(user)
                                    return req.redirect(to: "/admin")
                                 })
    }
    
    func logoutHandler(req: Request) throws -> Response {
        try req.unauthenticateSession(User.self)
        return req.redirect(to: "/")
    }
}

struct BlogsContext: Encodable {
    let blogs: Future<[BlogContext]>
}

struct UsersContext: Encodable {
    var username: String? = nil
    let users: Future<[User]>
}

struct UserContext: Content, Validatable, Reflectable {
    let username: String
    let password: String
    let confirmPassword: String
    
    static func validations() throws -> Validations<UserContext> {
        var validations = Validations(UserContext.self)
        try validations.add(\.username, .count(3...))
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

struct ErrorContext: Content {
    let error: String?
}

struct TagsContent: Encodable {
    let tags: Future<[Tag]>
}
