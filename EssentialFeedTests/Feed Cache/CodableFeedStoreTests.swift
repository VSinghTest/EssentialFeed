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



typealias FailableFeedStore = FailableRetrieveFeedStoreSpecs & FailableInsertFeedStoreSpecs & FailableDeleteFeedStoreSpecs
class CodableFeedStoreTests: XCTestCase, FailableFeedStore{
    
    
    
 //   this is the downside of not mocking the file system, good side is we are testing the real implementation but it leaves artifacts,side-effects,they may affect other tests or whole system. So we need to remove artifcats
    
    override func setUp() {
        super.setUp()// now test shoul know abt the internals of the test =>url
        
        setupEmptyStoreState()
    }
    
    
    
    override func tearDown() {// is invoked after every test method execution. but there is another problem very hard to debug. sometimes teardown method is not invoked, eg if you have crash in your system or even if you set a break point and if you finished the execution of a test before it finish running. so to pass this prob you have to write a  set up method
        super.tearDown()
        
        undoStoreSideEffects()

    }

    
    //MARK: - Retrival
   
    func test_retrieve_deliversEmptyOnEmptyCache(){
       let sut = makeSUT()
        assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache(){
        let sut = makeSUT()
        assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
       
  }
    
   func test_retrieve_deliversFoundValuesOnNonEmptyCache(){
        let sut = makeSUT()
        assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
    
   }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache(){
        let sut = makeSUT()
        assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
        
    }

    func test_retrieve_deliversFailureOnRetrivalError(){
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        expect(sut, toRetrieve: .failure(anyNSError()))
    }
    
    
    func test_retrieve_hasNoSideEffectsOnFailure(){
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        expect(sut, toRetrieveTwice: .failure(anyNSError()))
    }
    
    //MARK: -Insertion
    
    func test_insert_deliversNoErrorOnEmptyCache() {
            let sut = makeSUT()

            assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
        }

        func test_insert_deliversNoErrorOnNonEmptyCache() {
            let sut = makeSUT()
            
            assertThatInsertDeliversNoErrorOnNonEmptyCache(on: sut)
        }

        func test_insert_overridesPreviouslyInsertedCacheValues() {
            let sut = makeSUT()
            
            assertThatInsertOverridesPreviouslyInsertedCacheValues(on: sut)
        }
    
    
    func test_insert_deliversErrorOnInsertionError(){
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL: invalidStoreURL)
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        let insertionError = insert((feed, timestamp), to : sut)
        
        XCTAssertNotNil(insertionError, "expected cache insertion to fail with an error")
    }
    
    func test_insert_hasNoSideEffectsOnInsertionError() {
            let invalidStoreURL = URL(string: "invalid://store-url")!
            let sut = makeSUT(storeURL: invalidStoreURL)
            let feed = uniqueImageFeed().local
            let timestamp = Date()

            insert((feed, timestamp), to: sut)

        expect(sut, toRetrieve: .success(.empty))
        }

        func test_delete_deliversNoErrorOnEmptyCache() {
            let sut = makeSUT()
            assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
        }

        func test_delete_hasNoSideEffectsOnEmptyCache() {
            let sut = makeSUT()

            assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
        }
    
    
    
    
    func test_delete_deliversNoErrorOnNonEmptyCache() {
            let sut = makeSUT()
            assertThatDeleteDeliversNoErrorOnNonEmptyCache(on: sut)
        }

        func test_delete_emptiesPreviouslyInsertedCache() {
            let sut = makeSUT()
            assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
        }

        func test_delete_deliversErrorOnDeletionError() {
            let noDeletePermissionURL = cachesDirectory()
            let sut = makeSUT(storeURL: noDeletePermissionURL)

            let deletionError = deleteCache(from: sut)

            XCTAssertNotNil(deletionError, "Expected cache deletion to fail")
            expect(sut, toRetrieve: .success(.empty))
        }

        func test_delete_hasNoSideEffectsOnDeletionError() {
            let noDeletePermissionURL = cachesDirectory()
            let sut = makeSUT(storeURL: noDeletePermissionURL)

            deleteCache(from: sut)

            expect(sut, toRetrieve: .success(.empty))
        }
    func test_storeSideEffects_runSerially(){
        
        let sut = makeSUT()
        
        assertThatSideEffectsRunSerially(on: sut)
    
    }
    //the least side-effects u have the more concurrent your application can be. side-effecys are the enemy of concurrency
    
    
    
    
    
    
    //MARK: - Helpers
    
    private func makeSUT(storeURL: URL? = nil, file: StaticString = #file, line: UInt = #line) -> FeedStore{
         let sut = CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    

    private func setupEmptyStoreState(){
        deleteStoreArtifacts()
    }
    
    private func undoStoreSideEffects(){
        deleteStoreArtifacts()
    }
    
    private func deleteStoreArtifacts(){
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
}


