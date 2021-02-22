//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Vibha Singh on 2/8/21.
//

import XCTest
import EssentialFeed


class LoadFeedFromRemoteUseCaseTests: XCTestCase{
    
    func test_init_doesnotRequestDataFromURL(){
       let (_ , client) = makeSUT()
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    
    func test_load_requestsDataFromURL(){
        let url  = URL(string: "https://a-given-url.com")!
        let (sut , client) = makeSUT(url)
        
        sut.load{_ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    
    func test_loadTwice_requestsDataFromURL(){
        let url  = URL(string: "https://a-given-url.com")!
        let (sut , client) = makeSUT(url)
        
        sut.load{_ in }
        sut.load{_ in }
        
        XCTAssertEqual(client.requestedURLs, [url,url])
    }
    
    
    func test_load_deliversErrorOnClientError(){
        let (sut , client) = makeSUT()
        
        expect(sut, toCompleteWithResult: failure(.connectivity)) {
            let clientError = NSError(domain: "test", code: 0)
            client.complete(with: clientError)
        }
       
}
    
    func test_load_deliversErrorOnNon200HTTPResponse(){
        
        let (sut , client) = makeSUT()
        
        let samples = [199, 201, 300, 400, 500]
        samples.enumerated().forEach { (index, code) in
           
            expect(sut, toCompleteWithResult: failure(.invalidData)) {
                let json = makeItemsJSON([])
                client.complete(withStatusCode: code, data: json, at: index)
            }
        }
    }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON(){
        
        let (sut , client) = makeSUT()
        
        expect(sut, toCompleteWithResult: failure(.invalidData)) {
            let InvalidJSONData = Data("Invalid JSON".utf8)
           client.complete(withStatusCode: 200, data: InvalidJSONData)
        }
     }
    
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList(){
        
        let (sut , client) = makeSUT()
        
        expect(sut, toCompleteWithResult: .success([])) {
           let emptyJsonList = makeItemsJSON([])
           client.complete(withStatusCode: 200, data: emptyJsonList)
        }
        
     }
    
    func test_load_deliversItemsOn200HTTPResponseWithJSONItems(){
        
        let (sut , client) = makeSUT()
        
        let item1 = makeItem(
            id: UUID(),
            imageUrl: URL(string:"https://a-url.com")!)
        
        
        let item2 = makeItem(
            id: UUID(),
            description: "a description",
            location: "a loaction",
            imageUrl: URL(string:"https://other-url.com")!)
        
       
        expect(sut, toCompleteWithResult: .success([item1.model , item2.model])) {
            let json = makeItemsJSON([item1.json , item2.json])
            client.complete(withStatusCode: 200, data: json)
        }
     }
    
    
    
    func test_load_doesNotdelieverResultsAfterSUTHasBeenDeallocated(){
        
        let url = URL(string: "http://any-url.com")!
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(url: url, client: client)
        
        var capturedResults = [RemoteFeedLoader.Result]()
        sut?.load{ capturedResults.append($0)}
        
        sut = nil
        client.complete(withStatusCode: 200, data: makeItemsJSON([]))
        
        XCTAssertTrue(capturedResults.isEmpty)
        
    }
    
    
    //MARK: - Helpers
    
    private func makeSUT(_ url : URL = URL(string: "https://a-url.com")!)
    -> (sut: RemoteFeedLoader, client: HTTPClientSpy ){
        
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url:url, client:client)
        
        trackForMemoryLeaks( client)
        trackForMemoryLeaks( sut)
        return (sut , client)
    }
    

    private func makeItem(id: UUID, description: String? = nil, location: String? = nil , imageUrl: URL) -> (model: FeedImage, json: [String : Any]){
    
    let item = FeedImage(id: id, description: description, location: location, url: imageUrl)
        
    let json = [
        "id": id.uuidString,
        "description": description,
        "location": location,
        "image": imageUrl.absoluteString
    ].reduce(into: [String : Any]()) { (acc, e) in
        if let value = e.value{
            acc[e.key] = value}
        }
        return (item, json)
    }
    
     
    private func makeItemsJSON(_ items : [[String : Any]]) -> Data {
        
        let json = ["items" : items]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    
    
    private func failure(_ error: RemoteFeedLoader.Error) -> RemoteFeedLoader.Result{
        
        return .failure(error)
    }
    
    private func expect(_ sut: RemoteFeedLoader, toCompleteWithResult expectedResult:RemoteFeedLoader.Result, when action:() -> Void, file: StaticString = #filePath, line: UInt = #line) {
        
        let exp = expectation(description : "Wait for load completion")
        sut.load{ receivedResult in
            
            switch (receivedResult, expectedResult){
            case let (.success(receivedItems) , .success(expectedItems)):
                XCTAssertEqual(receivedItems  , expectedItems, file: file, line: line)
            case let (.failure(receivedError as RemoteFeedLoader.Error) , .failure(expectedError as RemoteFeedLoader.Error)):
                XCTAssertEqual(receivedError  , expectedError, file: file, line: line)
            default:
                XCTFail("Expected Result \(expectedResult) got \(receivedResult) instead", file: file, line: line)
            
            }
            
            exp.fulfill()
         }
       
         action()
         wait(for: [exp], timeout: 1.0)
    }
    
    
    private class HTTPClientSpy: HTTPClient{
        
        private var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        
        var requestedURLs: [URL]{
            return messages.map{ $0.url}
        }
        
        func get(from url : URL, completion: @escaping(HTTPClientResult) -> Void){
            messages.append((url, completion)) 
            
        }
        
        func complete(with error: Error, at index: Int = 0){
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode code: Int,data: Data , at index: Int = 0){
            
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )!
            messages[index].completion(.success(response, data))
        }
    }

}


