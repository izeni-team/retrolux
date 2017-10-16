//
//  ClientInheritanceTests.swift
//  RetroluxTests
//
//  Created by Christopher Bryan Henderson on 10/16/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation
import XCTest
import Retrolux

class ClientInheritanceTests: XCTestCase {
    func testInheritance() {
        class TestHTTPClient: HTTPClient {
            override init() {
                super.init()
                let configuration = URLSessionConfiguration.default
                configuration.timeoutIntervalForRequest = 5349786
                session = URLSession.init(configuration: configuration)
            }
        }
        
        let builder1 = Builder.dry()
        builder1.client = TestHTTPClient()
        let request1 = builder1.makeRequest(method: .post, endpoint: "endpoint", args: (), response: Void.self)
        _ = request1().perform()
        
        let builder2 = Builder.dry()
        builder2.client = HTTPClient()
        let request2 = builder2.makeRequest(method: .post, endpoint: "endpoint", args: (), response: Void.self)
        _ = request2().perform()
        
        let client1 = builder1.client as! HTTPClient
        XCTAssert(client1.session.configuration.timeoutIntervalForRequest == 5349786)
        let client2 = builder2.client as! HTTPClient
        XCTAssert(client2.session.configuration.timeoutIntervalForRequest != 5349786)
    }
}
