//
//  HTTPCall.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/8/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public typealias CallPerformFunction<ResponseType> = (RequestCapturedState) -> Response<ResponseType>

open class Call<T> {
    fileprivate var delegatedCapture: () -> RequestCapturedState
    fileprivate var delegatedPerform: CallPerformFunction<T>
    fileprivate var delegatedCancel: () -> Void
    
    public init(capture: @escaping () -> RequestCapturedState, perform: @escaping CallPerformFunction<T>, cancel: @escaping () -> Void) {
        self.delegatedCapture = capture
        self.delegatedPerform = perform
        self.delegatedCancel = cancel
    }
    
    open func perform() -> Response<T> {
        let state = delegatedCapture()
        return delegatedPerform(state)
    }
    
    open func enqueue(queue: DispatchQueue = .main, callback: @escaping (Response<T>) -> Void) {
        let state = delegatedCapture()
        DispatchQueue.global().async {
            let response = self.delegatedPerform(state)
            queue.async {
                callback(response)
            }
        }
    }
    
    open func cancel() {
        delegatedCancel()
    }
}
