//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Vibha Singh on 2/8/21.
//

import XCTest
import EssentialFeed


class RemoteFeedLoaderTests: XCTestCase{
    
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
        
        expect(sut, toCompleteWithResult: .failure(.connectivity)) {
            let clientError = NSError(domain: "test", code: 0)
            client.complete(with: clientError)
        }
       
}
    
    func test_load_deliversErrorOnNon200HTTPResponse(){
        
        let (sut , client) = makeSUT()
        
        let samples = [199, 201, 300, 400, 500]
        samples.enumerated().forEach { (index, code) in
            
            expect(sut, toCompleteWithResult: .failure(.invalidData)) {
                
                client.complete(withStatusCode: code, at: index)
                
            }
              
        }
        
    }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON(){
        
        let (sut , client) = makeSUT()
        
        expect(sut, toCompleteWithResult: .failure(.invalidData)) {
            let InvalidJSONData = Data("Invalid JSON".utf8)
            
           client.complete(withStatusCode: 200, data: InvalidJSONData)
       
        }
     }
    
    //MARK: - Helpers
    
    private func makeSUT(_ url : URL = URL(string: "https://a-url.com")!)
    -> (sut: RemoteFeedLoader, client: HTTPClientSpy ){
        
        let client = HTTPClientSpy()
        
        return (RemoteFeedLoader(url:url, client:client), client)
        
    }
     
   
    
    private func expect(_ sut: RemoteFeedLoader, toCompleteWithResult result:RemoteFeedLoader.Result, when action:() -> Void, file: StaticString = #filePath, line: UInt = #line) {
        
        var capturedResults = [RemoteFeedLoader.Result]()
     
         sut.load{
            capturedResults.append($0)
         }
       
         action()
         
         XCTAssertEqual(capturedResults, [result], file: file, line: line)
    
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
        
        func complete(withStatusCode code: Int,data: Data = Data(), at index: Int = 0){
            
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


