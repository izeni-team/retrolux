//
//  HTTPClientProtocol.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 7/15/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public struct HTTPClientResponseData {
    public let data: Data?
    public let status: Int?
    public let headers: [String: String]?
    public let error: Error?
    
    public init(data: Data?, status: Int?, headers: [String : String]?, error: Error?) {
        self.data = data
        self.status = status
        self.headers = headers
        self.error = error
    }
}

public protocol HTTPClientProtocol: class {
    var interceptor: ((inout URLRequest) -> Void)? { get set }
    
    func makeAsynchronousRequest(_ method: String, url: URL, body: Data?, headers: [String: String], callback: @escaping (_ httpResponse: HTTPClientResponseData) -> Void) -> HTTPTaskProtocol
}
