//
//  HTTPCall.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/8/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public typealias CallEnqueueFunction<ResponseType> = (RequestCapturedState, @escaping (Response<ResponseType>) -> Void) -> Void

open class Call<T> {
    fileprivate var delegatedCapture: () -> RequestCapturedState
    fileprivate var delegatedEnqueue: CallEnqueueFunction<T>
    fileprivate var delegatedCancel: () -> Void
    
    public init(capture: @escaping () -> RequestCapturedState, enqueue: @escaping CallEnqueueFunction<T>, cancel: @escaping () -> Void) {
        self.delegatedCapture = capture
        self.delegatedEnqueue = enqueue
        self.delegatedCancel = cancel
    }
    
    open func perform() -> Response<T> {
        let state = delegatedCapture()
        let semaphore = DispatchSemaphore(value: 0)
        var capturedResponse: Response<T>!
        delegatedEnqueue(state) { (response: Response<T>) in
            capturedResponse = response
            semaphore.signal()
        }
        semaphore.wait()
        return capturedResponse
    }
    
    open func enqueue(queue: DispatchQueue = .main, callback: @escaping (Response<T>) -> Void) {
        let state = delegatedCapture()
        
        state.workerQueue.async {
            self.delegatedEnqueue(state) { response in
                queue.async {
                    callback(response)
                }
            }
        }
    }
    
    open func cancel() {
        delegatedCancel()
    }
}
