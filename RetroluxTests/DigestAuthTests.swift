//
//  DigestAuthTests.swift
//  Retrolux
//
//  Created by Bryan Henderson on 1/23/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation
import XCTest
import Retrolux

fileprivate func plist(_ key: String) -> String {
    // http://stackoverflow.com/a/38035382/2406857
    let bundle = Bundle(for: BuilderTests.self)
    let path = bundle.path(forResource: "Sensitive", ofType: "plist")!
    let url = URL(fileURLWithPath: path)
    let data = try! Data(contentsOf: url)
    let plist = try! PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil)
    let dictionary = plist as! [String: Any]
    return dictionary[key] as! String
}

class DigestAuthTests: XCTestCase {
    /*func testDigestAuth() {
        class MyBuilder: Builder {
            let baseURL = URL(string: plist("URL"))!
            let client: Client = HTTPClient()
            let callFactory: CallFactory = HTTPCallFactory()
            let serializers: [Serializer] = [
                ReflectionJSONSerializer(),
                URLEncodedSerializer()
            ]
        }
        
        let builder = MyBuilder()
        
        builder.client.interceptor = { request in
            func md5(_ string: String) -> String {
                var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
                
                let data = string.data(using: .utf8)!
                _ = data.withUnsafeBytes { bytes in
                    CC_MD5(bytes, CC_LONG(data.count), &digest)
                }
                
                var digestHex = ""
                for index in 0..<Int(CC_MD5_DIGEST_LENGTH) {
                    digestHex += String(format: "%02x", digest[index])
                }
                
                return digestHex
            }
            
            // Algorithm for RFC 2069 taken from:
            // https://en.wikipedia.org/wiki/Digest_access_authentication
            let username = plist("DigestUsername")
            let realm = plist("DigestRealm")
            let password = plist("DigestPassword")
            let ha1 = md5("\(username):\(realm):\(password)")
            
            let method = "\(request.httpMethod ?? "")"
            let digestURI: String = {
                var url = "/"
                url += request.url!.absoluteString
                url = url.replacingOccurrences(of: builder.baseURL.absoluteString, with: "")
                url = url.removingPercentEncoding!
                return url
            }()
            let ha2 = md5("\(method):\(digestURI)")
            
            let nonce = ""
            let response = md5("\(ha1):\(nonce):\(ha2)")
            
            let headerValue = "Digest username=\"\(username)\", realm=\"\(realm)\", nonce=\"\(nonce)\", uri=\"\(digestURI)\", response=\"\(response)\", opaque=\"\""
            request.addValue(headerValue, forHTTPHeaderField: "Authorization")
        }
        
        let request = builder.makeRequest(method: .post, endpoint: "online/api/v2/app/login", args: Body<URLEncodedBody>(), response: Body<Void>())
        let expectation = self.expectation(description: "Waiting for network callback")
        let params = URLEncodedBody(values: [
            ("username", plist("username")),
            ("password", plist("password"))
            ])
        request(Body(params)).enqueue { (response: Response<Void>) in
            let status = response.raw?.status ?? 0
            XCTAssert(status == 200)
            print("HTTP \(status)")
            if status != 200 {
                if let data = response.raw?.data {
                    print("\n--- TEST FAILURE ---")
                    let string = String(data: data, encoding: .utf8)!
                    print("1: \(string)")
                    print("--- TEST FAILURE ---\n")
                }
                XCTFail("Unexpected status code of \(status)")
            } else {
                let pubs = builder.makeRequest(method: .get, endpoint: "online/api/v2/app/publications", args: (), response: Body<Void>())
                pubs().enqueue { (response: Response<Void>) in
                    let status2 = response.raw?.status ?? 0
                    print("HTTP \(status2)")
                    XCTAssert(status2 == 200)
                    if status2 != 200 {
                        if let data = response.raw?.data {
                            print("\n--- TEST FAILURE ---")
                            let string = String(data: data, encoding: .utf8)!
                            print("2: \(string)")
                            print("--- TEST FAILURE ---\n")
                        }
                    }
                    expectation.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: 5) { (error) in
            if let error = error {
                XCTFail("Failed to wait for expectation: \(error)")
            }
        }
    }*/
}
