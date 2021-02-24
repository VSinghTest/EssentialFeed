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


class CodableFeedStoreTests: XCTestCase {
    
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
       expect(sut, toRetrieve: .empty)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache(){
        let sut = makeSUT()
        expect(sut, toRetrieveTwice: .empty)
       
  }
    
   func test_retrieve_deliversFoundValuesOnNonEmptyCache(){
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        insert((feed, timestamp), to: sut)
        
        expect(sut, toRetrieve: .found(feed: feed, timestamp: timestamp))
  }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache(){
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        insert((feed, timestamp), to: sut)
       
        expect(sut, toRetrieveTwice: .found(feed: feed, timestamp: timestamp))
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
    
    func test_insert_overridesPreviouslyInsertedCacheValues(){
        let sut = makeSUT()
        
        let firstInsertionError = insert((uniqueImageFeed().local, Date()), to: sut)
        XCTAssertNil(firstInsertionError, "Expected to insert cache successfully")
        
        let latestFeed = uniqueImageFeed().local
        let latestTimestamp = Date()
        let latestInsertionError = insert((latestFeed, latestTimestamp), to: sut)
        
        XCTAssertNil(latestInsertionError, "Expected to override cacahe successfully")
        expect(sut, toRetrieve: .found(feed: latestFeed, timestamp: latestTimestamp))
    }
    
    
    func test_insert_deliversErrorOnInsertionError(){
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL: invalidStoreURL)
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        let insertionError = insert((feed, timestamp), to : sut)
        
        XCTAssertNotNil(insertionError, "expected cache insertion to fail with an error")
    }
    
    //MARK: -  Deletion
    
    
    func test_delete_hasNoSideEffectsOnEmptyCache() {
            let sut = makeSUT()
            let deletionError = deleteCache(from: sut)

            XCTAssertNil(deletionError, "Expected empty cache deletion to succeed")
            expect(sut, toRetrieve: .empty)
        }
    
    func test_delete_emptiesPreviouslyInsertedCache() {
            let sut = makeSUT()
            insert((uniqueImageFeed().local, Date()), to: sut)

//            let exp = expectation(description: "Wait for cache deletion")
//            sut.deleteCachedFeed { deletionError in
//                XCTAssertNil(deletionError, "Expected non-empty cache deletion to succeed")
//                exp.fulfill()
//            }
//            wait(for: [exp], timeout: 1.0)
            let deletionError = deleteCache(from: sut)

            XCTAssertNil(deletionError, "Expected non-empty cache deletion to succeed")
            expect(sut, toRetrieve: .empty)
        }
        
    func test_delete_deliversErrorOnDeletionError() {
            let noDeletePermissionURL = cachesDirectory()
            let sut = makeSUT(storeURL: noDeletePermissionURL)

            let deletionError = deleteCache(from: sut)

            XCTAssertNotNil(deletionError, "Expected cache deletion to fail")
            expect(sut, toRetrieve: .empty)
        }
    
    
    func test_storeSideEffects_runSerially(){
        
        let sut = makeSUT()
        
        var completedOperationInOrder = [XCTestExpectation]()
        let op1 = expectation(description: "Operation 1")
        sut.insert(uniqueImageFeed().local, timestamp: Date()) { _ in
            completedOperationInOrder.append(op1)
            op1.fulfill()
        }
        
        let op2 = expectation(description: "Operation 2")
        sut.deleteCachedFeed{ _ in
            completedOperationInOrder.append(op2)
            op2.fulfill()
        }
        
        let op3 = expectation(description: "Operation 3")
        sut.insert(uniqueImageFeed().local, timestamp: Date()){ _ in
            completedOperationInOrder.append(op3)
            op3.fulfill()
        }
        waitForExpectations(timeout: 5.0)
        XCTAssertEqual(completedOperationInOrder, [op1, op2, op3], "Expected side-effects to run serially but operations finished in the wrong order")
    }
    
    
    
    
    
    
    
    //MARK: - Helpers
    
    private func makeSUT(storeURL: URL? = nil, file: StaticString = #file, line: UInt = #line) -> FeedStore{
         let sut = CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    @discardableResult
    private func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: FeedStore)-> Error?{
        let exp = expectation(description: "Wait for cache insertion")
        var insertionError: Error?
        sut.insert(cache.feed, timestamp: cache.timestamp){ receivedInsertionError in
           insertionError = receivedInsertionError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return insertionError
    }
    
    
   
    private func deleteCache(from sut: FeedStore) -> Error? {
            let exp = expectation(description: "Wait for cache deletion")
            var deletionError: Error?
            sut.deleteCachedFeed { receivedDeletionError in
                deletionError = receivedDeletionError
                exp.fulfill()
            }
            wait(for: [exp], timeout: 1.0)
            return deletionError
        }
    
    private func expect(_ sut: FeedStore, toRetrieve expectedResult: RetrieveCachedFeedResult, file: StaticString = #file, line: UInt = #line){
        
        let exp = expectation(description: "Wait for cache retrieval")
         
        sut.retrieve{ retrieveResult in
             switch (expectedResult,retrieveResult) {
             case (.empty, .empty),(.failure, .failure):
                 break
            
             case let(.found(expected), .found(retrieved)):
                XCTAssertEqual(retrieved.feed, expected.feed, file: file, line: line)
                XCTAssertEqual(retrieved.timestamp, expected.timestamp, file: file, line: line)
             
             default:
                 XCTFail("Expected to retrieve \(expectedResult), got \(retrieveResult) instead")
             }
             exp.fulfill()
             }
        wait(for: [exp], timeout: 1.0)
        }
    
    
    
    
    private func expect(_ sut:FeedStore , toRetrieveTwice expectedResult: RetrieveCachedFeedResult, file: StaticString = #file, line: UInt = #line){
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
    }
         
    
    private func testSpecificStoreURL() -> URL{
       return FileManager.default.urls(for: .cachesDirectory, in : .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
       
    }
    
    private func cachesDirectory() -> URL {
            return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
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


