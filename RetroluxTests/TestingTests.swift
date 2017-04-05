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
        
        let builder = Builder.dummy()
        XCTAssert(builder.isDryModeEnabled == false)
        
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
        var response = createUser(newPerson).test()
        print(response.body!.name)
        XCTAssert(response.body!.name == "George")
        XCTAssert(response.isSuccessful)
        
        builder.isDryModeEnabled = true
        
        response = createUser(newPerson).perform()
        XCTAssert(response.status == 200)
        XCTAssert(response.body!.name == "George")
        XCTAssert(response.headers.isEmpty)
        XCTAssert(response.isSuccessful)
        
        XCTAssert(builder.isDryModeEnabled == true)
        builder.isDryModeEnabled = false
        
        response = createUser(newPerson).perform()
        XCTAssert(response.body == nil)
        XCTAssert(response.isSuccessful == false)
        
        XCTAssert(builder.isDryModeEnabled == false)
    }
}
