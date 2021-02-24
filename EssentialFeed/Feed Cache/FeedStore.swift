//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Vibha Singh on 2/21/21.
//

import Foundation

public enum RetrieveCachedFeedResult{
    
    case empty
    case found(feed:[LocalFeedImage], timestamp: Date)
    case failure(Error)
}

// In FeedStore case the side effects overlapped. when u delete a cache u affect the insert. when u insert u also affect the delete and reteive affected by all of them. this can become messy quickly. so before we begin we must fully understand our expectations on the infrastructure implementation.

public protocol FeedStore{
    
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    typealias RetrievalCompletion = (RetrieveCachedFeedResult) -> Void
    
    
    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads, if needed.
    func deleteCachedFeed(completion: @escaping DeletionCompletion)
    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads, if needed.
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion)
    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads, if needed.
    func retrieve(completion:@escaping RetrievalCompletion)
}


