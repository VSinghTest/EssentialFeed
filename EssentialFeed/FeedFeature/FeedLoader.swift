//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Vibha Singh on 2/7/21.
//

import Foundation

public enum LoadFeedResult<Error: Swift.Error>{
    
    case success([FeedItem])
    case failure(Error)
}


extension LoadFeedResult: Equatable where Error: Equatable{}

public protocol FeedLoader{
    
    associatedtype Error: Swift.Error
    
    func load(completion: @escaping(LoadFeedResult<Error>) -> Void)
}
