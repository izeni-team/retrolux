//
//  BuilderTests.swift
//  Retrolux
//
//  Created by Bryan Henderson on 12/12/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import XCTest
import Retrolux

class BuilderTests: XCTestCase {
    class MyBuilder: Builder {
        var baseURL: URL
        var client: Client
        var callFactory: CallFactory
        var serializer: Serializer
        
        init() {
            self.baseURL = URL(string: "https://www.google.com/")!
            self.client = HTTPClient()
            self.callFactory = HTTPCallFactory()
            self.serializer = ReflectionJSONSerializer()
        }
    }
    
    func createBuilder() -> Builder {
        return MyBuilder()
    }
}
