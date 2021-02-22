//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Vibha Singh on 2/9/21.
//

import Foundation

// we don't have use cases to allow subclassing so make it final

public final class RemoteFeedLoader: FeedLoader {
    
    
    private let url: URL
    private let client: HTTPClient
    
    public enum Error: Swift.Error{
        case connectivity
        case invalidData
    }
    
    public typealias Result = LoadFeedResult
    
    
    public init(url: URL, client: HTTPClient) {
        self.client = client
        self.url = url
    }
    
    public func load(completion: @escaping(Result) -> Void ) {
        
        client.get(from : url){ [weak self] result in
            guard let _ = self else{
                return
            }
            switch result{
            case let .success( response, data):
                completion(RemoteFeedLoader.map(data, from:response))
                
            case .failure: completion(.failure(Error.connectivity))
            }
        }
    }
    
    private static func map(_ data: Data, from response: HTTPURLResponse) -> Result{
        do{
            let items = try FeedItemsMapper.map(data, from: response)
            return .success(items.toModels())
        }catch{
            return .failure(error)
        }
    }
}


private extension Array where Element == RemoteFeedItem{
    func toModels() -> [FeedItem]{
     return map{ FeedItem(id: $0.id, description: $0.description, location: $0.location, imageUrl: $0.image)}
    }
}





