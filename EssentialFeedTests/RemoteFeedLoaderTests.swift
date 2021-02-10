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
        
        sut.load()
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    
    func test_loadTwice_requestsDataFromURL(){
        let url  = URL(string: "https://a-given-url.com")!
        let (sut , client) = makeSUT(url)
        
        sut.load()
        sut.load()
        
       
        XCTAssertEqual(client.requestedURLs, [url,url])
    }
    
    
    func test_load_deliversErrorOnClientError(){
        let (sut , client) = makeSUT()
        client.error = NSError(domain: "test", code: 0)
        var capturedError : RemoteFeedLoader.Error?
        sut.load{ error in
            capturedError = error
        }
        
        XCTAssertEqual(capturedError, .connectivity)
    }
    //MARK: - Helpers
    
    private func makeSUT(_ url : URL = URL(string: "https://a-url.com")!)
    -> (sut: RemoteFeedLoader, client: HTTPClientSpy ){
        
        let client = HTTPClientSpy()
        
        return (RemoteFeedLoader(url:url, client:client), client)
        
    }
    
   
    
    private class HTTPClientSpy: HTTPClient{
        
       
        var requestedURLs =  [URL]()
        var error : Error?
        func get(from url : URL, completion:(Error) -> Void){
            
            if let error = error {
                completion(error)
            }
            requestedURLs.append(url)
        }
        
    }

}


