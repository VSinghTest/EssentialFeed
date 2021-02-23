//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Vibha Singh on 2/12/21.
//

import Foundation

public enum HTTPClientResult{
    
    case success(HTTPURLResponse, Data)
    case failure(Error)
}

// Httpclient doesn't perform side effect. get method is query. it should return the same result so its' much simpler to test operation there should not side effect
public protocol HTTPClient{
    func get(from url : URL , completion: @escaping(HTTPClientResult) -> Void)
}
