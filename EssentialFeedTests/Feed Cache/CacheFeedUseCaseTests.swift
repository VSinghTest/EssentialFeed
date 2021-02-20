//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Vibha Singh on 2/20/21.
//

import XCTest

class LocalFeedLoader{
    init(store: FeedStore){
        
    }
}



class FeedStore{
    var deleteCachedfeedCallCount = 0
}
class CacheFeedUseCaseTests: XCTestCase {
    
    func test_init_doesNotDeleteCacheUponCreation(){
        
        let store = FeedStore()
        _ = LocalFeedLoader(store: store)
        XCTAssertEqual(store.deleteCachedfeedCallCount, 0)
    }

   
}
