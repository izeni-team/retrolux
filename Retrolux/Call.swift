//
//  Call.swift
//  Retrolux
//
//  Created by Mitchell Tenney on 9/9/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation


class Call<T> {
    var request: NSMutableURLRequest?
    //var task: HTTP
    
    fileprivate(set) var isExecuted: Bool = false
    fileprivate(set) var isCancelled = false

    func enqueue(_ callback: (_ response: RLResponse<T>) -> Void) -> Call<T> {
        assert(!isExecuted, "Cannot execute call more than once.")
        isExecuted = true
        
        guard !isCancelled else {
            return self
        }
        
        //callback()
        return self
    }
    
    func cancel() {
        isCancelled = true
        fatalError("TODO: Cancel HTTP task")
    }
}
