//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Vibha Singh on 2/20/21.
//

import XCTest
import EssentialFeed


class CacheFeedUseCaseTests: XCTestCase {
    
    func test_init_doesNotMessageStoreUponCreation(){
        
        let (_ , store) = makeSUT() // To decouple the application from framework details, we don't let frameworks dictate the UseCase interfaces(e.g. adding Codable requirements or Coredata managed contexts parametrs)
        //We do so by test-driving the interfaces the Use case needs for its collaborators, rather than defining the interface upfront to facilitate a specfic framework implementattion.
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    
    func test_save_requestsCacheDeletion(){
       
        let (sut , store) = makeSUT()
        
        sut.save(uniqueImageFeed().models){_ in}
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }
    
    func test_save_doesnotRequestCacheInsertionOnDeletionError(){
        
       
        let (sut , store) = makeSUT()
        let deletionError = anyNSError()
        
        sut.save(uniqueImageFeed().models){_ in}
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }
    

    
    func test_save_requestsNewCacheInsertionwithTimeStampOnSucessfullyDeletion(){
        let timestamp = Date()
        let feed = uniqueImageFeed()
        let (sut , store) = makeSUT(currentDate: {timestamp})

        sut.save(feed.models){_ in}
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed, .insert(feed.local, timestamp)])
    }
    
    func test_save_failsOnDeletionError(){
        
        let (sut , store) = makeSUT()
        let deletionError = anyNSError()
        
        expect(sut, toCompleteWithError: deletionError, when: {
           
            store.completeDeletion(with: deletionError)
        })
    }
    
    
    func test_save_failsOnInsertionError(){
        
        let (sut , store) = makeSUT()
        let insertionError = anyNSError()
        
        expect(sut, toCompleteWithError: insertionError, when: {
            store.completeDeletionSuccessfully()
            store.completeInsertion(with: insertionError)
        })
       
    }
    
    func test_save_succeedsOnSuccessfullCacheInsertion(){
        
        let (sut , store) = makeSUT()
        
        expect(sut, toCompleteWithError: nil, when: {
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        })
        
        
    }
    
    
    func test_save_doesNotDeliverDeletionErrorAfterSUTInstanceHasBeenDeallocated(){
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var receivedResults = [LocalFeedLoader.SaveResult]()
        sut?.save(uniqueImageFeed().models){
            receivedResults.append($0)}
        
    
        sut = nil
        store.completeDeletion(with: NSError())
        XCTAssertTrue(receivedResults.isEmpty)
    }

    func test_save_doesNotDeliverInsertionErrorAfterSUTInstanceHasBeenDeallocated(){
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var receivedResults = [LocalFeedLoader.SaveResult]()
        sut?.save(uniqueImageFeed().models){
            receivedResults.append($0)}
        
        store.completeDeletionSuccessfully()
        sut = nil
        store.completeInsertion(with: anyNSError())
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
   //MARK: - Helpers
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy){
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate : currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
       return ( sut , store)
    }
    
    
    private func expect(_ sut: LocalFeedLoader, toCompleteWithError expectedError: NSError?, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line){
        let exp = expectation(description: "wait for completion")
        
        var receivedError: Error?
        sut.save(uniqueImageFeed().models){ error in
            receivedError = error
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(receivedError as NSError?, expectedError, file: file, line: line)
    }
    
    
    private func uniqueImage() -> FeedImage{
        return FeedImage(id: UUID(), description: "unique Item", location: nil, url: anyURL())
    }
    
    
    private func uniqueImageFeed() -> (models:[FeedImage], local: [LocalFeedImage]){
        let models = [uniqueImage(), uniqueImage()]
        let local = models.map{ LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)
        }
        return (models,local)
    }
    
    
    private func anyURL() -> URL{
       return  URL(string: "http://any-url.com")!
    }
    
    private func anyNSError() -> NSError{
        NSError(domain: "any error", code: 0)
    }
    
    
    
    
}
