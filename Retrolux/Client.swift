//
//  Client.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/8/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public typealias ClientResponse = (
    data: Data?,
    status: Int?,
    headers: [String: String]?,
    error: Error?
)

public protocol Client: class {
    var interceptor: ((inout URLRequest) -> Void)? { get set }
    func makeAsynchronousRequest(request: URLRequest, callback: @escaping (_ httpResponse: ClientResponse) -> Void) -> Task
}
