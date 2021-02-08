//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Vibha Singh on 2/7/21.
//

import Foundation

enum LoadFeedResult{
    
    case success([FeedItem])
    case error(Error)
}

protocol FeedLoader{
    
    func loadItem(completion: @escaping(LoadFeedResult) -> Void)
}
