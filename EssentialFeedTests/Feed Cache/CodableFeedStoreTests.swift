//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Vibha Singh on 2/23/21.
//
//Insert
//    - To empty cache works
//    - To non-empty cache overrides previous value
//    - Error (if possible to simulate, e.g., no write permission)
//**************************
//- Delete
//    - Empty cache does nothing (cache stays empty and does not fail)
//    - Inserted data leaves cache empty
//    - Error (if possible to simulate, e.g., no write permission)
//***************************
//- Retrieve
//    - Empty cache works (before something is inserted)
//    - Empty cache twice returns empty(no side-effects)
//    - Non-empty cache returns data
//    - Non-empty cache twice returns same data (retrieve should have no side-effects)
//    - Error returns error (if possible to simulate, e.g., invalid data)
//    - Error twice returns same error (if possible to simulate, e.g., invalid data)
//****************************
//- Side-effects must run serially to avoid race-conditions (deleting the wrong cache... overriding the latest data...)
import XCTest
import EssentialFeed

class CodableFeedStore{
    func retrieve(completion:@escaping FeedStore.RetrievalCompletion){
        completion(.empty)
    }
}
class CodableFeedStoreTests: XCTestCase {

    func test_retrieve_deliversemptyOnEmptyCache(){
        let sut = CodableFeedStore()
       let exp = expectation(description: "Wait for cache retrieval")
        sut.retrieve{ result in
            switch result{
            case .empty:
                break
            default:
                XCTFail("Expected empty result, got \(result) instead")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache(){
        let sut = CodableFeedStore()
       let exp = expectation(description: "Wait for cache retrieval")
        sut.retrieve{ firstResult in
            sut.retrieve{secondResult in
            switch (firstResult,secondResult) {
            case (.empty, .empty):
                break
            default:
                XCTFail("Expected retrieving twice from empty cache to deliver same empty result, got \(firstResult) and \(secondResult) instead")
            }
            exp.fulfill()
            }
            
        }
        wait(for: [exp], timeout: 1.0)
       
    }
}
