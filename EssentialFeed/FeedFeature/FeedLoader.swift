//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Vibha Singh on 2/7/21.
//

import Foundation

public typealias LoadFeedResult = Result<[FeedImage], Error>
    
 

public protocol FeedLoader{
    
   func load(completion: @escaping(LoadFeedResult) -> Void)
}
