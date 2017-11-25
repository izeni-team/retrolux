//
//  RequestBuilderTests.swift
//  RetroluxTests
//
//  Created by Christopher Bryan Henderson on 11/24/17.
//  Copyright © 2017 Christopher Bryan Henderson. All rights reserved.
//

import Foundation
import XCTest
@testable import Retrolux

class RequestBuilderTests: XCTestCase {
    func testExample1() {
        struct Repo {}
        class GitHubService: RequestBuilder {
            func listRepos(for user: String) -> Call<[Repo]> {
                return get("users/%@/repos", user).build()
            }
        }
        
        let service = GitHubService(base: URL(string: "https://api.github.com/")!)
        _ = service.listRepos(for: "octocat")
    }
    
    func testExample2() {
        class SomeService: RequestBuilder {
            func example() {
                _ = get("users/list")
                _ = get("users/list?sort=desc")
            }
        }
    }
    
    func testExample3() {
        struct User {}
        class SomeService: RequestBuilder {
            func groupList(id: Int) -> Call<[User]> {
                return get("group/%@/users", id).build()
            }
            
            func groupList(id: Int, sort: String) -> Call<[User]> {
                return get("group/%@/users", id).query("sort", sort).build()
            }
            
            func groupList(id: Int, options: [String: String]) -> Call<[User]> {
                return get("group/%@/users", id).queries(options).build()
            }
        }
    }
    
    func testExample4() {
        struct User {}
        
        class SomeService: RequestBuilder {
            func create(user: User) -> Call<User> {
                return post("users/new").body(user).build()
            }
        }
    }
    
    func testExample5() {
        struct User {}
        
        class SomeService: RequestBuilder {
            func updateUser(firstName: String, lastName: String) -> Call<User> {
                let fields = [
                    Field(name: "first_name", value: firstName),
                    Field(name: "last_name", value: lastName)
                ]
                return post("user/edit").formUrlEncoded.body(fields).build()
            }
            
            func updateUser(photo: RequestBody, description: RequestBody) -> Call<User> {
                let body = [
                    Part(name: "photo", body: photo),
                    Part(name: "description", body: description)
                ]
                return post("user/photo").multipart.body(body).build()
            }
        }
    }
    
    func testExample6() {
        struct Widget {}
        struct User {}
        
        class SomeService: RequestBuilder {
            func widgetList() -> Call<[Widget]> {
                return get("widget/list").header("Cache-Control", "max-age=640000").build()
            }
            
            func getUser(username: String) -> Call<User> {
                let headers = [
                    "Accept": "application/vnd.github.v3.full+json",
                    "User-Agent": "Retrofit-Sample-App"
                ]
                return get("username/%@", username).headers(headers).build()
            }
            
            func getUser(authorization: String) -> Call<User> {
                return get("user").header("Authorization", authorization).build()
            }
        }
    }
    
    func testExample7() {
        class GitHubService: RequestBuilder {}
        
        let service = GitHubService(base: URL(string: "https://api.github.com/")!)
        service.encoders.append(JSONBodyEncoder())
        service.decoders.append(JSONBodyDecoder())
    }
}
