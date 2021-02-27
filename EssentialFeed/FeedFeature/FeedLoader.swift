//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Vibha Singh on 2/7/21.
//

import Foundation

 

public protocol FeedLoader{
   
    typealias Result = Swift.Result<[FeedImage], Error>
        
 func load(completion: @escaping(Result) -> Void)
}

