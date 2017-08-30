//
//  Request.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 8/21/17.
//  Copyright © 2017 Christopher Bryan Henderson. All rights reserved.
//

import Foundation

public struct Response<R> {
    public let status: Int?
    public let body: R?
    public let headers: [String: String]?
    public let error: Error?
    public let request: URLRequest
    
    public var isSuccessful: Bool {
        return false
    }
}

public protocol Call {
    var isCancelled: Bool { get }
    mutating func cancel()
}

struct URLSessionCall: Call {
    let task: URLSessionTask
    
    var isCancelled: Bool {
        return task.state == .canceling
    }
    
    func cancel() {
        task.cancel()
    }
}

public struct RequestData: Equatable {
    public var url: URL
    public var method: String
    public var headers: [String: String]
    
    public init(url: URL, method: String, headers: [String: String]) {
        self.url = url
        self.method = method
        self.headers = headers
    }
}

public func ==(lhs: RequestData, rhs: RequestData) -> Bool {
    return lhs.url == rhs.url && lhs.method == rhs.method && lhs.headers == rhs.headers
}

public struct ResponseData: Equatable {
    public let body: Data?
    public let status: Int?
    public let headers: [String: String]?
    public let error: Error?
    
    public static let empty = ResponseData(body: nil, status: nil, headers: nil, error: nil)
    
    public init(body: Data?, status: Int?, headers: [String: String]?, error: Error?) {
        self.body = body
        self.status = status
        self.headers = headers
        self.error = error
    }
}

public func ==(lhs: ResponseData, rhs: ResponseData) -> Bool {
    return lhs.body == rhs.body && lhs.status == rhs.status && lhs.headers ?? [:] == rhs.headers ?? [:]
}

fileprivate let workerQueue = DispatchQueue(label: "Retrolux.Request")

struct RequestCall: Call {
    let requestQueue = DispatchQueue(label: "Retrolux.RequestCall")
    private var _isCancelled = false
    var isCancelled: Bool {
        get {
            return requestQueue.sync {
                _isCancelled
            }
        }
        set {
            requestQueue.sync {
                _isCancelled = newValue
            }
        }
    }
    
    var internalCall: Call?
    
    mutating func cancel() {
        requestQueue.sync {
            _isCancelled = true
            internalCall?.cancel()
        }
    }
}

public struct Request<A, R, C> {
    // The data of the request. HTTP method, URL, headers, body, etc., can all be found in here.
    public var data: URLRequest
    
    // If set, then the Builder should perform a dry run on this request.
    // A dry run means that the request should be executed with the given
    // response data and no network calls should be actually performed.
    // Useful for unit testing.
    public var simulatedResponse: ResponseData?
    
    // First argument is the request itself.
    // Second argument contains the arguments required to start the request.
    // Third argument is the simulated response data. If non-nil, it means that a dry run should be performed.
    // Fourth argument is the user-facing callback.
    internal var factory: (Request<A, R, C>, A, ResponseData?, @escaping (R) -> Void) -> C
    
    // Starts the request asynchronously.
    // TODO: Finish implementing this, and make encoding happen on a worker queue.
    public func enqueue(_ args: A, _ callback: @escaping (R) -> Void) -> C {
        return self.factory(self, args, nil, callback)
    }
    
    public func test(_ args: A, simulated: ResponseData) -> R {
        var response: R!
        _ = factory(self, args, simulated, { (r) in
            response = r
        })
        return response
    }
    
    public func perform(_ args: A) -> R {
        let semaphore = DispatchSemaphore(value: 0)
        var response: R!
        _ = factory(self, args, nil, { (r) in
            response = r
            semaphore.signal()
        })
        semaphore.wait()
        return response
    }
}

public extension Request where A == Void {
    public func enqueue(_ callback: @escaping (R) -> Void) -> C {
        return enqueue((), callback)
    }
    
    public func perform() -> R {
        return perform(())
    }
    
    public func test(_ simulated: ResponseData) -> R {
        return test((), simulated: simulated)
    }
}
