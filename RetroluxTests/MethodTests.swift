//
//  MethodTests.swift
//  RetroluxTests
//
//  Created by Christopher Bryan Henderson on 8/28/17.
//  Copyright © 2017 Christopher Bryan Henderson. All rights reserved.
//

import Foundation
import XCTest

class MethodTests: XCTestCase {
    func testMethods() {
        let builder = makeTestBuilder()
        
        let request = builder.make(.get("whatever"), response: Void.self)
        XCTAssert(request.data.httpMethod == "GET")
        
        let postRequest = builder.make(.post("whatever"), response: Void.self)
        XCTAssert(postRequest.data.httpMethod == "POST")
        
        let deleteRequest = builder.make(.delete("whatever"), response: Void.self)
        XCTAssert(deleteRequest.data.httpMethod == "DELETE")
        
        let headRequest = builder.make(.head("whatever"), response: Void.self)
        XCTAssert(headRequest.data.httpMethod == "HEAD")
        
        let putRequest = builder.make(.put("whatever"), response: Void.self)
        XCTAssert(putRequest.data.httpMethod == "PUT")
        
        let optionsRequest = builder.make(.options("whatever"), response: Void.self)
        XCTAssert(optionsRequest.data.httpMethod == "OPTIONS")
        
        let patchRequest = builder.make(.patch("PATCH"), response: Void.self)
        XCTAssert(patchRequest.data.httpMethod == "PATCH")
    }
}
