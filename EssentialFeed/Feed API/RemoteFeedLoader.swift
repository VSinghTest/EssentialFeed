//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Vibha Singh on 2/9/21.
//

import Foundation


public enum HTTPClientResult{
    
    case success(HTTPURLResponse, Data)
    case failure(Error)
}

public protocol HTTPClient{
    func get(from url : URL , completion: @escaping(HTTPClientResult) -> Void)
}

// we don't have use cases to allow subclassing so make it final

public final class RemoteFeedLoader {
    
    private let url: URL
    private let client: HTTPClient
    
    public enum Error: Swift.Error{
        case connectivity
        case invalidData
    }
    
    public enum Result: Equatable{
        case success([FeedItem])
        case failure(Error)
    }
    
    public init(url: URL, client: HTTPClient) {
        self.client = client
        self.url = url
    }
    
    public func load(completion: @escaping(Result) -> Void ) {
       
        client.get(from : url){ result in
            
            switch result{
            case let .success(_ , data):
                if let _ =  try? JSONSerialization.jsonObject(with: data){
                    completion(.success([]))
                }else{
                    completion(.failure(.invalidData))
                }
            case .failure: completion(.failure(.connectivity))
            }
        }
    }
}


