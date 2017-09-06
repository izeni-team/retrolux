//
//  JSONDecoderTests.swift
//  RetroluxTests
//
//  Created by Christopher Bryan Henderson on 9/6/17.
//  Copyright © 2017 Christopher Bryan Henderson. All rights reserved.
//

import Foundation
import XCTest
import Retrolux

fileprivate struct Person: Decodable, Equatable {
    let name: String
    let age: Int
}

fileprivate func ==(lhs: Person, rhs: Person) -> Bool {
    return lhs.name == rhs.name && lhs.age == rhs.age
}

class JSONDecoderTests: XCTestCase {
    func testArrayGet() {
        func testListOfPeople() {
            let builder = Builder(base: URL(string: "https://my.api.com/")!)
            let getUsers = builder.make(
                .get("users/"),
                response: [Person].self
            )
            let json = """
[{"name":"Bob","age":20},{"name":"Anna","age":19}]
""".utf8
            let response = getUsers.test(ResponseData(body: json, status: 200, headers: nil, error: nil))
            XCTAssert(response.body ?? [] == [
                Person(name: "Bob", age: 20),
                Person(name: "Anna", age: 19)
                ])
        }
    }
}
