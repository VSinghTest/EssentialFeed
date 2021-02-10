//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Vibha Singh on 2/9/21.
//

import Foundation

public protocol HTTPClient{
    func get(from url : URL , completion: @escaping(Error?, HTTPURLResponse?) -> Void)
}

// we don't have use cases to allow subclassing so make it final

public final class RemoteFeedLoader {
    
    private let url: URL
    private let client: HTTPClient
    
    public enum Error: Swift.Error{
        case connectivity
        case invalidData
    }
    
    public init(url: URL, client: HTTPClient) {
        self.client = client
        self.url = url
    }
    
    public func load(completion: @escaping(Error) -> Void ) {
        client.get(from : url){
            error, response in
            if  error != nil {
                completion(.connectivity)
            }else{
                completion(.invalidData)
            }
        }
    }
}


