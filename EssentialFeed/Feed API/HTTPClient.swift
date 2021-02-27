//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Vibha Singh on 2/12/21.
//

import Foundation

// Httpclient doesn't perform side effect. get method is query. it should return the same result so its' much simpler to test operation there should not side effect
public protocol HTTPClient{
    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads, if needed.
    typealias Result = Swift.Result<(HTTPURLResponse, Data), Error>
    func get(from url : URL , completion: @escaping(Result) -> Void)
}

