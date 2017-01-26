//
//  MultipartFormDataSerializerTests.swift
//  Retrolux
//
//  Created by Bryan Henderson on 1/26/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation
import XCTest
import Retrolux

class MultipartFormDataSerializerTests: XCTestCase {
    func testSinglePart() {
        let builder = RetroluxBuilder(baseURL: URL(string: "http://127.0.0.1/")!)
        let request = builder.makeRequest(method: .post, endpoint: "whatever/", args: Part(name: "file", filename: "image.png", mimeType: "image/png"), response: Body<Void>())
        
        let expectation = self.expectation(description: "Waiting for response")
        
        let image = UIImage(named: "something")!
        let data = UIImagePNGRepresentation(image)!
        
        request(Part(data)).enqueue { response in
            let bundle = Bundle(for: type(of: self))
            let url = bundle.url(forResource: "request", withExtension: "data")!
            let data = try! Data(contentsOf: url)
            let asciiExpected = String(data: data, encoding: .ascii)!
            
            var asciiRequest = String(data: response.request.httpBody!, encoding: .ascii)!
            let staticBoundary = "alamofire.boundary.b990eade8c5319d6"
            asciiRequest = asciiRequest.replacingOccurrences(of: "alamofire\\.boundary\\.[0-9a-f]{16,16}", with: staticBoundary, options: .regularExpression)
            
            XCTAssert(asciiExpected == asciiRequest)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1) { (error) in
            if error != nil {
                XCTFail("Failed with error: \(error)")
            }
        }
    }
}
