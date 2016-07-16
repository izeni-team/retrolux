//
//  RetroluxTests.swift
//  RetroluxTests
//
//  Created by Christopher Bryan Henderson on 7/12/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import XCTest
import Retrolux

protocol HTTPClient {
}

protocol HTTPTask {
    func cancel()
}

struct MockHTTPTask: HTTPTask {
    let mockResponse: (data: NSData?, status: Int?, error: NSError?)
    var callback: (data: NSData?, status: Int?, error: NSError?) -> Void
    
    init(mockResponse: (data: NSData?, status: Int?, error: NSError?), callback: (data: NSData?, status: Int?, error: NSError?) -> Void) {
        self.mockResponse = mockResponse
        self.callback = callback
    }
    
    func cancel() {}
}

class MockHTTPClient: HTTPClient {
    var mockResponse: (data: NSData?, status: Int?, error: NSError?)!
    
    func makeRequest(method: String, url: NSURL, body: NSData?, headers: [String: String], callback: (data: NSData?, status: Int?, error: NSError?) -> Void) ->HTTPTask {
        let task = MockHTTPTask(mockResponse: mockResponse, callback: callback)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            task.callback(data: task.mockResponse.data, status: task.mockResponse.status, error: task.mockResponse.error)
        }
        return task
    }
}

// Notes:
// HTTPClient must run an a completely different queue or else risks deadlocks when being performed synchronously.
// Add support for multiple serializers in next version

class RetroluxTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testGET() {
//        class Person: RLObject {
//            dynamic var name = ""
//            dynamic var age = 0
//            dynamic var friends = [Person]()
//        }
//        
//        let manager = Retrolux(baseURL: NSURL(string: "https://www.doesnotmatter.com")!)
//        let mockClient = MockHTTPClient()
//        manager.client = mockClient
//        manager.serializer = JSONSerializer()
//        
//        let jsonData = "{\"name\":\"Bryan\",\"age\":23,\"friends\":[{{\"name\":\"Bryan\",\"age\":23,\"friends\":[]}}]}".dataUsingEncoding(NSUTF8StringEncoding)
//        mockClient.mockResponse = (jsonData, 200, nil)
//        let task = manager.GET("/api/people/", output: Person.self)
//        let response = task.perform()
//        switch response {
//        case .Success(let result):
//            print(result.value)
//            let json = try! NSJSONSerialization.JSONObjectWithData(jsonData!, options: [])
//            let person = result.value
//            XCTAssert(person.name == json["name"])
//            XCTAssert(person.age == json["age"])
//            XCTAssert(person.friends.count == 1)
//            guard let friend = person.friends.first, friendsJSON = json["friends"] as? [[String: AnyObject]], friendJSON = friendsJSON.first else {
//                XCTFail("Failed to find friend")
//                return
//            }
//            XCTAssert(friend.name == friendJSON["name"])
//            XCTAssert(friend.age == friendJSON["age"])
//            XCTAssert(friend.friends == [])
//            XCTAssert(result.status == 200)
//        case .Error(let error):
//            XCTFail("\(error)")
//        }
    }
}
