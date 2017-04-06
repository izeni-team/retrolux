//
//  TestingTests.swift
//  Retrolux
//
//  Created by Bryan Henderson on 4/5/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation
import Retrolux
import XCTest

class TestingTests: XCTestCase {
    func testTest1() {
        class Person: Reflection {
            var name = ""
        }
        
        let builder = Builder.dry()
        XCTAssert(builder.isDryModeEnabled == true)
        XCTAssert(Builder(base: URL(string: "https://www.google.com/")!).isDryModeEnabled == false)
        
        let createUser = builder.makeRequest(
            method: .post,
            endpoint: "users/",
            args: Person(),
            response: Person.self,
            testProvider: { (creation, starting, request) in
                ClientResponse(
                    url: request.url!,
                    data: "{\"name\":\"\(starting.name)\"}".data(using: .utf8)!,
                    headers: [:],
                    status: 200,
                    error: nil
                )
            }
        )
        
        let newPerson = Person()
        newPerson.name = "George"
        var response = createUser(newPerson).perform()
        XCTAssert(response.status == 200)
        XCTAssert(response.error == nil)
        XCTAssert(response.body!.name == "George")
        XCTAssert(response.headers.isEmpty)
        XCTAssert(response.isSuccessful)
        
        let wetBuilder = Builder(base: URL(string: "8.8.8.8/")!)
        XCTAssert(wetBuilder.isDryModeEnabled == false)
        let wetCreateUser = wetBuilder.makeRequest(
            method: .post,
            endpoint: "users/",
            args: Person(),
            response: Person.self
        )
        
        response = wetCreateUser(newPerson).perform()
        XCTAssert(response.body?.name == nil)
        XCTAssert(response.isSuccessful == false)
    }
}
