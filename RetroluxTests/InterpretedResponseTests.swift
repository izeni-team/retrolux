//
//  InterpretedResponseTests.swift
//  Retrolux
//
//  Created by Bryan Henderson on 4/4/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation
import Retrolux
import XCTest

class InterpretedResponseTests: XCTestCase {
    func testUnsupportedArg() {
        let builder = Builder.dry()
        builder.responseInterceptor = { response in
            response = ClientResponse(base: response, status: 200, data: nil)
        }
        let function = builder.makeRequest(method: .get, endpoint: "whateverz", args: 1, response: Void.self)
        switch function(2).perform().interpreted {
        case .success(_):
            XCTFail("Should not have succeeded.")
        case .failure(let error):
            if case BuilderError.unsupportedArgument(let arg) = error {
                XCTAssert(arg.creation as? Int == 1)
                XCTAssert(arg.starting as? Int == 2)
                XCTAssert(arg.type == Int.self)
            } else {
                XCTFail("Wrong error returned: \(error); expected an unsupported argument error instead.")
            }
        }
    }

    func testInvalidHttpStatusCode() {
        class Person: Reflection {
            var name: String = ""
            
            required init() {
                
            }
            
            init(name: String) {
                self.name = name
            }
        }
        
        let function = Builder.dry().makeRequest(method: .post, endpoint: "whateverz", args: Person(name: "Alice"), response: Person.self, testProvider: {
            ClientResponse(url: $0.2.url!, data: "{\"name\":null}".data(using: .utf8)!, headers: [:], status: 400, error: nil)
        })
        switch function(Person(name: "Bob")).perform().interpreted {
        case .success(_):
            XCTFail("Should not have succeeded.")
        case .failure(let error):
            if case ResponseError.invalidHttpStatusCode(code: let code) = error {
                XCTAssert(code == 400)
            } else {
                XCTFail("Wrong error returned: \(error); expected an invalid HTTP status code error instead.")
            }
        }
    }
    
    func testResponseSerializationError() {
        class Person: Reflection {
            var name: String = ""
        }
        
        let function = Builder.dry().makeRequest(method: .post, endpoint: "whateverz", args: (), response: Person.self) {
            ClientResponse(url: $0.2.url!, data: "{\"name\":null}".data(using: .utf8)!, status: 200)
        }
        switch function().perform().interpreted {
        case .success(_):
            XCTFail("Should not have succeeded.")
        case .failure(let error):
            if case ReflectorSerializationError.propertyDoesNotSupportNullValues(propertyName: let propertyName, forClass: let `class`) = error {
                XCTAssert(propertyName == "name")
                XCTAssert(`class` == Person.self)
            } else {
                XCTFail("Wrong error returned: \(error).")
            }
        }
    }
    
    func testSuccess() {
        class Person: Reflection {
            var name: String = ""
        }
        
        let function = Builder.dry().makeRequest(method: .post, endpoint: "whateverz", args: (), response: Person.self) {
            ClientResponse(url: $0.2.url!, data: "{\"name\":\"bobby\"}".data(using: .utf8)!, status: 200)
        }
        switch function().perform().interpreted {
        case .success(let person):
            XCTAssert(person.name == "bobby")
        case .failure(let error):
            XCTFail("Response interpreted as failure: \(error)")
        }
    }
    
    func testHTTP400ErrorWithInvalidJSONResponse() {
        class Person: Reflection {
            var name = ""
        }
        
        let function = Builder.dry().makeRequest(method: .post, endpoint: "whatevers", args: (), response: Person.self) {
            ClientResponse(url: $0.2.url!, data: "ERROR".data(using: .utf8)!, status: 400)
        }
        switch function().perform().interpreted {
        case .success:
            XCTFail("Should not have succeeded")
        case .failure(let error):
            if case ResponseError.invalidHttpStatusCode = error {
                
            } else {
                XCTFail("Expected an invalid HTTP error, but got the following instead: \(error)")
            }
        }
    }
    
    func testNoInternet() {
        let builder = Builder.dry()
        let request = builder.makeRequest(
            method: .get,
            endpoint: "",
            args: (),
            response: Void.self
        ) { _ in
            return ClientResponse(data: nil, response: nil, error: NSError(domain: "Whatever", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Localized Description",
                NSLocalizedRecoverySuggestionErrorKey: "Recovery Suggestion"
                ]))
        }
        
        switch request().perform().interpreted {
        case .success:
            XCTFail("Should not have succeeded.")
        case .failure(let error):
            if case ResponseError.connectionError = error {
                XCTAssert(error.localizedDescription == "Localized Description")
                XCTAssert((error as NSError).localizedRecoverySuggestion == "Recovery Suggestion")
            } else {
                XCTFail("Unexpected error code: \(error)")
            }
        }
    }
    
    func testResponsePublicInitializer() {
        _ = Response<Void>(
            request: URLRequest(url: URL(string: "https://www.google.com/")!),
            data: nil,
            error: nil,
            urlResponse: nil,
            body: nil,
            interpreted: InterpretedResponse<Void>.failure(NSError(domain: "ERR_TEST", code: 3, userInfo: nil))
        )
    }
}
