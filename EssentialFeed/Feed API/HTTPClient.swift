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

public protocol HTTPClient{
    func get(from url : URL , completion: @escaping(HTTPClientResult) -> Void)
}
