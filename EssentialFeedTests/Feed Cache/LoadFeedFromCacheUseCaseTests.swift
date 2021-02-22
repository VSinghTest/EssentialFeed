//
//  LoadFeedFromCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Vibha Singh on 2/22/21.
//

import XCTest
import EssentialFeed
class LoadFeedFromCacheUseCaseTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation(){
        // This test may look duplicate, but it's an "accidental duplication". Although we decided to keep the "save" and "Load" methods in the same type (LocalFeedLoader), they belong to different contexts/ Use Cases.
        //  By creating separate tests, if we ever decide to break those actions in separate types, it's much easier to do so. The tests are already separated and with all the necessary assertions.
        //  Don't Repeat Yourself is a good principle, but not every code that looks alike is duplicate. Before deleting duplication, investigate if it's just an accidental duplication: code that seems the same but conceptually represents something else.
        //  Mixing different concepts makes it harder to reason anout separate parts of the system in isolation, increasing its complexity.
        let (_ , store) = makeSUT()
    
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    
    func test_load_requestsCacheRetrieval(){
        
        let (sut , store) = makeSUT()
        
        sut.load(){ _ in }
    
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_failsOnRetrievalError(){
        let (sut , store) = makeSUT()
        let retrievalError = anyNSError()
        let exp = expectation(description: "Wait for load completion")
        var receivedError: Error?
        sut.load(){ result in
            switch result{
            case let .failure(error):
                receivedError = error
            default:
                XCTFail("Expected Failure, got \(result) instead")
            }
           
            exp.fulfill()
        }
    
        store.completeRetrieval(with: retrievalError)
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(receivedError as NSError?, retrievalError)
        
    }
    
    // MARK: - Helpers
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy){
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate : currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
       return ( sut , store)
    }
    private func anyNSError() -> NSError{
        NSError(domain: "any error", code: 0)
    }
}
