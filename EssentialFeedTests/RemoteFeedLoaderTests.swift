//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Vibha Singh on 2/8/21.
//

import XCTest


class RemoteFeedLoader{
    
    let client: HTTPClient
    let url: URL
    
    init(url: URL = URL(string: "https://a-url.com")!, client: HTTPClient){
        
        self.client = client
        self.url = url
    }
    
    func  load(){
        
        client.get(from : url)
    }
}

protocol HTTPClient{
    

    func get(from url : URL)
  
}

class HTTPClientSpy: HTTPClient{
    
    func get(from url : URL){
        requestedURL = url
    }
    var requestedURL: URL?
}


class RemoteFeedLoaderTests: XCTestCase{
    
    func test_init_doesnotRequestDataFromURL(){
        
        let client = HTTPClientSpy()
        
        _ = RemoteFeedLoader(client:client)
        
        
        XCTAssertNil(client.requestedURL)
    }
    
    
    func test_load_requestDataFromURL(){
        
        let client = HTTPClientSpy()
        let url  = URL(string: "https://a-given-url.com")!
        let sut = RemoteFeedLoader(url:url,client:client)
        sut.load()
        
        XCTAssertEqual(client.requestedURL, url)
    }
}


