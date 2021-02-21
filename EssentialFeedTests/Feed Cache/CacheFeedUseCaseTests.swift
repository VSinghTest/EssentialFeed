//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Vibha Singh on 2/20/21.
//

import XCTest
import EssentialFeed

class LocalFeedLoader{
    private let store: FeedStore
    private let currentDate: () -> Date
    
    init(store: FeedStore, currentDate:@escaping () -> Date ){
        self.store = store
        self.currentDate = currentDate
    }
    
    func save( _ items: [FeedItem], completion: @escaping(Error?) -> Void){
        store.deleteCachedFeed{ [unowned self] error in
            completion(error)
            if error == nil{
               self.store.insert(items, timestamp: self.currentDate())
            }
        }
    }
}


class FeedStore{
    typealias DeletionCompletion = (Error?) -> Void
    
    enum ReceivedMessage: Equatable{
        case deleteCachedFeed
        case insert([FeedItem], Date)
    }
    
    private(set) var receivedMessages = [ReceivedMessage]()
    
    private var deletionCompletions = [DeletionCompletion]()
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion){
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCachedFeed)
    }
    
    func completionDeletion(with error: Error, at index: Int = 0){
        deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0){
        deletionCompletions[index](nil)
    }
    
    func insert(_ items: [FeedItem], timestamp: Date){
        receivedMessages.append(.insert(items, timestamp))
    }
}


class CacheFeedUseCaseTests: XCTestCase {
    
    func test_init_doesNotMessageStoreUponCreation(){
        
        let (_ , store) = makeSUT() // To decouple the application from framework details, we don't let frameworks dictate the UseCase interfaces(e.g. adding Codable requirements or Coredata managed contexts parametrs)
        //We do so by test-driving the interfaces the Use case needs for its collaborators, rather than defining the interface upfront to facilitate a specfic framework implementattion.
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    
    func test_save_requestsCacheDeletion(){
       
        let items = [uniqueItem(), uniqueItem()]
        let (sut , store) = makeSUT()
        
        sut.save(items){_ in}
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }
    
    func test_save_doesnotRequestCacheInsertionOnDeletionError(){
        
        let items = [uniqueItem(), uniqueItem()]
        let (sut , store) = makeSUT()
        let deletionError = anyNSError()
        
        sut.save(items){_ in}
        store.completionDeletion(with: deletionError)
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }
    

    
    func test_save_requestsNewCacheInsertionwithTimeStampOnSucessfullyDeletion(){
        let timestamp = Date()
        let items = [uniqueItem(), uniqueItem()]
        let (sut , store) = makeSUT(currentDate: {timestamp})

        sut.save(items){_ in}
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed, .insert(items, timestamp)])
    }
    
    func test_save_failsOnDeletionError(){
        
        let items = [uniqueItem(), uniqueItem()]
        let (sut , store) = makeSUT()
        let deletionError = anyNSError()
        
        let exp = expectation(description: "wait for completion")
        
        var receivedError: Error?
        sut.save(items){ error in
            receivedError = error
            exp.fulfill()
        }
        
        store.completionDeletion(with: deletionError)
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(receivedError as NSError?, deletionError)
    }
    
    
   //MARK: - Helpers
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStore){
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store, currentDate : currentDate)
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
