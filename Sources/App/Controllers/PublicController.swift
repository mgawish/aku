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
import MailCore
import GoogleAnalyticsProvider

class PublicController: RouteCollection {
    func boot(router: Router) throws {
        //index and apps
        router.get(use: indexViewHandler)
        router.get("apps", Blog.parameter, use: blogDetailsViewHanlder)
        router.get(String.parameter, use: taggedBlogsViewHandler)
        
        //contact
        router.get("contact", use: contactViewHandler)
        router.post(EmailContent.self, at: "send_email", use: sendEmailHandler)
        router.get("email_confirmation", use: emailConfirmationViewHandler)
        
        //auth
        router.get("login", use: loginViewHandler)
        router.post(LoginContent.self, at: "login", use: loginHandler)
        router.get("logout", use: logoutHandler)
        
        //admin
        let adminRoutes = router.grouped([User.authSessionsMiddleware(),
                                          RedirectMiddleware<User>(path: "/login")])
        
        adminRoutes.get("admin", use: adminBlogsViewHandler)
        adminRoutes.get("admin", "apps", use: adminBlogsViewHandler)
        adminRoutes.get("admin", "users", use: adminUsersViewHandler)

        adminRoutes.get("admin", "apps", "create", use: createBlogViewHandler)
        adminRoutes.post(Blog.Data.self, at: "admin", "apps", "create", use: createBlogHandler)
        adminRoutes.get("admin", "apps", Blog.parameter, use: editBlogViewHandler)
        adminRoutes.post(Blog.Data.self, at: "admin", "apps", Blog.parameter, "edit", use: editBlogHandler)
        adminRoutes.post( "admin", "apps", Blog.parameter, "delete", use: deleteBlogHandler)
        
        adminRoutes.get("admin", "users", "create", use: createUserViewHandler)
        adminRoutes.post(UserContent.self, at: "admin", "users", "create", use: createUserHandler)
        adminRoutes.get("admin", "users", User.parameter, use: editUserViewHandler)
        adminRoutes.post(UserContent.self, at: "admin", "users", User.parameter, "edit", use: editUserHandler)
        
        adminRoutes.get("admin", "tags", use: adminTagsViewHandler)
    }
    
    //MARK:- Public
    func indexViewHandler(req: Request) throws -> Future<View> {
        return Blog.query(on: req)
            .sort(\.order)
            .filter(\.isActive == true)
            .all()
            .flatMap(to: View.self, { blogs in
                let blogs = try blogs.compactMap({ try $0.convertToData(req: req) }).flatten(on: req)
                let tags = Tag.query(on: req).all()
                return try req.view().render("index", BlogsContent(allTags: tags, blogs: blogs))
            })
    }
    
    func taggedBlogsViewHandler(req: Request) throws -> Future<View> {
        let tagName = try req.parameters.next(String.self)
        return Blog.query(on: req)
            .sort(\.order)
            .filter(\.isActive == true)
            .join(\BlogTagPivot.blogId, to: \Blog.id)
            .join(\Tag.id, to: \BlogTagPivot.tagId)
            .alsoDecode(Tag.self)
            .filter(\Tag.name == tagName)
            .all()
            .flatMap(to: View.self, { result in
                let blogs = try result.compactMap({ try $0.0.convertToData(req: req) }).flatten(on: req)
                return try req.view().render("index", BlogsContent(tagName: tagName,
                                                                   blogs: blogs))
            })
    }
    
    func blogDetailsViewHanlder(req: Request) throws -> Future<View> {
        return try req.parameters.next(Blog.self).flatMap(to: View.self) { blog in
            return try req.view().render("blogDetails", blog.convertToData(req: req))
        }
    }
    
    
    func contactViewHandler(req: Request) throws -> Future<View> {
        let error = req.query[String.self, at: "error"]
        return try req.view().render("contact", ErrorContent(error: error))
    }
    
    func sendEmailHandler(req: Request, data: EmailContent) throws -> Future<Response> {
        do {
            try data.validate()
        } catch {
            return req.future(req.redirect(to: "/contact?error=\(error.localizedDescription.urlEndcoded())"))
        }
        
        let gac = try req.make(GoogleAnalyticsClient.self)
        gac.send(hit: .event(category: "Contact", action: "Send Email"))
        
        let mail = Mailer.Message(from: Environment.get("FROM_EMAIL") ?? "",
                                  to: Environment.get("TO_EMAIL") ?? "",
                                  subject: data.subject,
                                  text: "Some one reached out",
                                  html: """
                                        <p><strong>Email</strong></p>
                                        <p>\(data.email)</p>
                                        <p><strong>Name</strong></p>
                                        <p>\(data.name)</p>
                                        <p><strong>Message</strong></p>
                                        <p>\(data.message)</p>
                                        """)
        
        return try req.mail.send(mail).map(to: Response.self, { response in
            return req.redirect(to: "/email_confirmation")
        })
    }
    
    func emailConfirmationViewHandler(req: Request) throws -> Future<View> {
        return try req.view().render("emailConfirmation")
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
                let data = try blogs.map({ try $0.convertToData(req: req)}).flatten(on: req)
                return try req.view().render("adminBlogs", BlogsContent(blogs: data))
            })
    }
    
    func createBlogViewHandler(req: Request) throws -> Future<View> {
        _ = try req.requireAuthenticated(User.self)
        return try req.view().render("adminModifyBlog")
    }
    
    func createBlogHandler(req: Request, data: Blog.Data) throws -> Future<View> {
        _ = try req.requireAuthenticated(User.self)
        let blog = Blog(data)
        return blog
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
            return try req.view().render("adminModifyBlog", blog.convertToData(req: req))
        }
    }
    
    func editBlogHandler(req: Request, data: Blog.Data) throws -> Future<View> {
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
                                     UsersContent(users: User.query(on: req).all()))
    }
    
    func createUserViewHandler(req: Request) throws -> Future<View> {
        _ = try req.requireAuthenticated(User.self)
        return try req.view().render("adminModifyUser")
    }
    
    func createUserHandler(req: Request, data: UserContent) throws -> Future<View> {
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
    
    func editUserHandler(req: Request, data: UserContent) throws -> Future<View> {
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
        return try req.view().render("login", ErrorContent(error: error))
    }
    
    func loginHandler(req: Request, data: LoginContent) throws -> Future<Response> {
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

struct BlogsContent: Encodable {
    var tagName: String? = nil
    var allTags: Future<[Tag]>? = nil
    let blogs: Future<[Blog.Data]>
}

struct UsersContent: Encodable {
    var username: String? = nil
    let users: Future<[User]>
}

struct UserContent: Content, Validatable, Reflectable {
    let username: String
    let password: String
    let confirmPassword: String
    
    static func validations() throws -> Validations<UserContent> {
        var validations = Validations(UserContent.self)
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

struct LoginContent: Content, Validatable, Reflectable {
    let username: String
    let password: String
    
    static func validations() throws -> Validations<LoginContent> {
        var validations = Validations(LoginContent.self)
        try validations.add(\.username, .count(3...))
        try validations.add(\.password, .count(3...))
        return validations
    }
}

struct ErrorContent: Content {
    let error: String?
}

struct TagsContent: Encodable {
    let tags: Future<[Tag]>
}

struct EmailContent: Content, Validatable, Reflectable {
    let email: String
    let name: String
    let subject: String
    let message: String
    
    static func validations() throws -> Validations<EmailContent> {
        var validations = Validations(EmailContent.self)
        try validations.add(\.email, .email)
        return validations
    }
}
