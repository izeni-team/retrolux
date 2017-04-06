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
        let request = Builder.dry().makeRequest(method: .post, endpoint: "whatever/", args: Part(name: "file", filename: "image.png", mimeType: "image/png"), response: Void.self)
        
        let image = Utils.testImage
        let imageData = UIImagePNGRepresentation(image)!
        
        let response = request(Part(imageData)).perform()
        let bundle = Bundle(for: type(of: self))
        let url = bundle.url(forResource: "request", withExtension: "data")!
        let responseData = try! Data(contentsOf: url)
        let asciiExpected = String(data: responseData, encoding: .ascii)!
        
        var asciiRequest = String(data: response.request.httpBody!, encoding: .ascii)!
        let staticBoundary = "alamofire.boundary.b990eade8c5319d6"
        asciiRequest = asciiRequest.replacingOccurrences(of: "alamofire\\.boundary\\.[0-9a-f]{16,16}", with: staticBoundary, options: .regularExpression)
        
        XCTAssert(asciiExpected == asciiRequest)
        XCTAssert(response.request.value(forHTTPHeaderField: "Content-Type")?.hasPrefix("multipart/form-data; boundary=alamofire.boundary.") == true)
    }
    
    func testMultipleParts() {
        let request = Builder.dry().makeRequest(method: .post, endpoint: "whatever/", args: (Field("first_name"), Field("last_name")), response: Void.self)
        
        let response = request((Field("Bryan"), Field("Henderson"))).perform()
        let bundle = Bundle(for: type(of: self))
        let url = bundle.url(forResource: "testmultipleparts", withExtension: "data")!
        let data = try! Data(contentsOf: url)
        let asciiExpected = String(data: data, encoding: .ascii)!
        
        var asciiRequest = String(data: response.request.httpBody!, encoding: .ascii)!
        let staticBoundary = "alamofire.boundary.3ffb270bf5e2dc3b"
        asciiRequest = asciiRequest.replacingOccurrences(of: "alamofire\\.boundary\\.[0-9a-f]{16,16}", with: staticBoundary, options: .regularExpression)
        
        XCTAssert(asciiExpected == asciiRequest)
        XCTAssert(response.request.value(forHTTPHeaderField: "Content-Type")?.hasPrefix("multipart/form-data; boundary=alamofire.boundary.") == true)
    }
    
    func testFieldsAndPartsCombined() {
        struct RequestData {
            let firstName: Field
            let imagePart: Part
        }
        
        let request = Builder.dry().makeRequest(
            method: .post,
            endpoint: "whatever/",
            args: RequestData(firstName: Field("first_name"), imagePart: Part(name: "file", filename: "image.png", mimeType: "image/png")),
            response: Void.self
        )
        
        let image = Utils.testImage
        let imageData = UIImagePNGRepresentation(image)!
        
        let requestData = RequestData(
            firstName: Field("Bob"),
            imagePart: Part(imageData)
        )
        
        let response = request(requestData).perform()
        let bundle = Bundle(for: type(of: self))
        let url = bundle.url(forResource: "fieldsandpartscombined", withExtension: "data")!
        let data = try! Data(contentsOf: url)
        let asciiExpected = String(data: data, encoding: .ascii)!
        
        var asciiRequest = String(data: response.request.httpBody!, encoding: .ascii)!
        let staticBoundary = "alamofire.boundary.5483ad401099117f"
        asciiRequest = asciiRequest.replacingOccurrences(of: "alamofire\\.boundary\\.[0-9a-f]{16,16}", with: staticBoundary, options: .regularExpression)
        
        XCTAssert(asciiExpected == asciiRequest)
        XCTAssert(response.request.value(forHTTPHeaderField: "Content-Type")?.hasPrefix("multipart/form-data; boundary=alamofire.boundary.") == true)
    }
    
    func testScopeForField() {
        let f = Field("username")
        XCTAssert(f.value == "username")
    }
}
