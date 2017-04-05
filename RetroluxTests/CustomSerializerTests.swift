//
//  CustomSerializerTests.swift
//  Retrolux
//
//  Created by Bryan Henderson on 4/4/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation
import Retrolux
import XCTest

class CustomSerializerTests: XCTestCase {
    func testCustomSerializer() {
        let builder = Builder.dry()
        builder.serializers.append(SwiftyJSONSerializer())
        let function = builder.makeRequest(
            method: .post,
            endpoint: "login/",
            args: JSON([:]),
            response: JSON.self
        )
        builder.responseInterceptor = { response in
            response = ClientResponse(base: response, status: 200, data: "{\"token\":\"123\",\"id\":\"abc\"}".data(using: .utf8)!)
        }
        
        let response = function(JSON(["username": "bobby", "password": "abc123"])).perform()
        let requestDictionary = try! JSONSerialization.jsonObject(with: response.request.httpBody!, options: []) as! [String: Any]
        XCTAssert(requestDictionary.keys.count == 2)
        XCTAssert(requestDictionary["username"] as? String == "bobby")
        XCTAssert(requestDictionary["username"] as? String == "bobby")
        
        let responseDictionary = try! JSONSerialization.jsonObject(with: response.data!, options: []) as! [String: Any]
        XCTAssert(responseDictionary.keys.count == 2)
        XCTAssert(responseDictionary["token"] as? String == "123")
        XCTAssert(responseDictionary["id"] as? String == "abc")
        
        XCTAssert(response.body!["token"] == "123")
        XCTAssert(response.body!["id"] == "abc")
    }
}
