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
    
    private struct Cache: Codable{
        let feed: [CodableFeedImage]
        let timestamp: Date
        
        var localFeed: [ LocalFeedImage ] {
            return feed.map{ $0.local }
        }
    }
    
    private struct CodableFeedImage: Codable{
        private let id: UUID
        private let description: String?
        private let location: String?
        private let url:   URL
        
        init(_ image: LocalFeedImage){
            id = image.id
            description = image.description
            location = image.location
            url = image.url
        }
        
        var local: LocalFeedImage{
            return LocalFeedImage(id: id, description: description, location: location, url: url)
        }
    }
    
    private let storeURL: URL
    
    init(storeURL: URL){
        self.storeURL = storeURL
    }
    
    func retrieve(completion:@escaping FeedStore.RetrievalCompletion){
        guard let data = try? Data(contentsOf: storeURL) else{
            return completion(.empty)
        }
        let decoder = JSONDecoder()
        let cache = try! decoder.decode(Cache.self, from: data)
        completion(.found(feed: cache.localFeed , timestamp: cache.timestamp))
    }
    
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertionCompletion){
        
        let encoder = JSONEncoder()
        let cache = Cache(feed: feed.map(CodableFeedImage.init), timestamp: timestamp)
        let encoded = try! encoder.encode(cache)
        try! encoded.write(to: storeURL)
        completion(nil)
    }
}

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

    
 //Mark: - Retrival
   
    func test_retrieve_deliversemptyOnEmptyCache(){
       let sut = makeSUT()
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
        let sut = makeSUT()
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
    
    //Mark: - Insertion
    
    func test_retrieveAfterInsertingToEmptyCache_deliversInsertedValues(){
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
       let exp = expectation(description: "Wait for cache retrieval")
        sut.insert(feed, timestamp: timestamp){ insertionError in
            XCTAssertNil(insertionError, "Expected feed to be inserted successfully")
            
            sut.retrieve{retrieveResult in
                switch (retrieveResult) {
                case let .found(retrivedFeed, retrievedTimestamp):
                    XCTAssertEqual(retrivedFeed, feed)
                    XCTAssertEqual(retrievedTimestamp, timestamp)
                default:
                    XCTFail("Expected found result with \(feed) and timestamp \(timestamp), got \(retrieveResult) instead")
                }
                exp.fulfill()
            }
            
        }
        wait(for: [exp], timeout: 1.0)
  }
    
    
    //MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> CodableFeedStore{
         let sut = CodableFeedStore(storeURL: testSpecificStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func testSpecificStoreURL() -> URL{
       return FileManager.default.urls(for: .cachesDirectory, in : .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
       
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


