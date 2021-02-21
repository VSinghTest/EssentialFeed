//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Vibha Singh on 2/20/21.
//

import XCTest
import EssentialFeed

class LocalFeedLoader{
    private var store: FeedStore
   
    init(store: FeedStore){
        self.store = store
    }
    
    func save( _ items: [FeedItem]){
        store.deleteCachedFeed{ [unowned self] error in
            if error == nil{
               
                self.store.insert(items)
                
            }
        }
    }
}

class FeedStore{
    typealias DeletionCompletion = (Error?) -> Void
    
    var deleteCachedfeedCallCount = 0
    var insertCallCount = 0
    
    private var deletionCompletions = [DeletionCompletion]()
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion){
        deleteCachedfeedCallCount += 1
        deletionCompletions.append(completion)
    }
    
    func completionDeletion(with error: Error, at index: Int = 0){
        deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0){
        deletionCompletions[index](nil)
    }
    
    func insert(_ items: [FeedItem]){
        insertCallCount += 1
    }
}


class CacheFeedUseCaseTests: XCTestCase {
    
    func test_init_doesNotDeleteCacheUponCreation(){
        
        let (_ , store) = makeSUT() // To decouple the application from framework details, we don't let frameworks dictate the UseCase interfaces(e.g. adding Codable requirements or Coredata managed contexts parametrs)
        //We do so by test-driving the interfaces the Use case needs for its collaborators, rather than defining the interface upfront to facilitate a specfic framework implementattion.
        XCTAssertEqual(store.deleteCachedfeedCallCount, 0)
    }
    
    
    func test_save_requestsCacheDeletion(){
       
        let items = [uniqueItem(), uniqueItem()]
        let (sut , store) = makeSUT()
        
        sut.save(items)
        
        XCTAssertEqual(store.deleteCachedfeedCallCount, 1)
    }
    
    func test_save_doesnotRequestCacheInsertionOnDeletionerror(){
        
        let items = [uniqueItem(), uniqueItem()]
        let (sut , store) = makeSUT()
        let deletionError = anyNSError()
        
        sut.save(items)
        store.completionDeletion(with: deletionError)
        
        XCTAssertEqual(store.insertCallCount, 0)
    }
    

    func test_save_requestsNewCacheInsertionOnSucessfullDeletion(){
        let items = [uniqueItem(), uniqueItem()]
        let (sut , store) = makeSUT()

        sut.save(items)
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.insertCallCount, 1)
        
    }
   //MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStore){
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
       return ( sut , store)
    }
    
    private func uniqueItem() -> FeedItem{
        return FeedItem(id: UUID(), description: "unique Item", location: nil, imageUrl: anyURL())
    }
    
    private func anyURL() -> URL{
       return  URL(string: "http://any-url.com")!
    }
    
    private func anyNSError() -> NSError{
        NSError(domain: "any error", code: 0)
    }
    
    
}
