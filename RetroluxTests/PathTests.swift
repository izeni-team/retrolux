//
//  PathTests.swift
//  Retrolux
//
//  Created by Bryan Henderson on 1/26/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation
import XCTest
import Retrolux

class PathTests: XCTestCase {
    func testSinglePath() {
        let builder = RetroluxBuilder(baseURL: URL(string: "http://127.0.0.1/")!)
        let request = builder.makeRequest(method: .get, endpoint: "whatever/{id}/", args: Path("id"), response: Void.self)
        
        let expectation = self.expectation(description: "Waiting for response")
        
        request(Path("some_id_thing")).enqueue { response in
            XCTAssert(response.request.url?.absoluteString.hasSuffix("whatever/some_id_thing/") == true)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1) { (error) in
            if error != nil {
                XCTFail("Failed with error: \(error)")
            }
        }
    }
    
    func testMultiplePaths() {
        let builder = RetroluxBuilder(baseURL: URL(string: "http://127.0.0.1/")!)
        let request = builder.makeRequest(method: .get, endpoint: "whatever/{id}/{id2}/", args: (Path("id"), Path("id2")), response: Void.self)
        
        let expectation = self.expectation(description: "Waiting for response")
        
        request((Path("some_id_thing"), Path("another_id_thing"))).enqueue { response in
            XCTAssert(response.request.url?.absoluteString.hasSuffix("whatever/some_id_thing/another_id_thing/") == true)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1) { (error) in
            if error != nil {
                XCTFail("Failed with error: \(error)")
            }
        }
    }
}
