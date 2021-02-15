//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Vibha Singh on 2/13/21.
//

import XCTest

class URLSessionHTTPClient{
    
    private let session: URLSession
    
    init(session: URLSession){
        self.session = session
    }
    
    func get(from url: URL){
        session.dataTask(with: url){ _, _, _ in }.resume()
    }
}

class URLSessionHTTPClientTests: XCTestCase {

    func test_getfromURL_createsDataTaskWithURL(){
        
        let url = URL(string: "http://any-url.com")!
        let session = URLSessionSpy()
        let sut = URLSessionHTTPClient(session: session)
        
        sut.get(from: url)
        
        XCTAssertEqual(session.receivedURLs, [url])
    }
    
    
    func test_getfromURL_resumesDataTaskWithURL(){
        
        let url = URL(string: "http://any-url.com")!
        let session = URLSessionSpy()
        let task = URLSessionDataTaskSpy()
        
        session.stub(url: url, task: task)
        let sut = URLSessionHTTPClient(session: session)
        sut.get(from: url)
        
        XCTAssertEqual(task.resumeCallCount, 1)
    }
//MARK: - Helpers
    
   private class URLSessionSpy: URLSession{
        var receivedURLs = [URL]()
        private var stubs = [URL: URLSessionDataTask]()
        
        func stub(url: URL, task: URLSessionDataTask){
         
            stubs[url] = task
        }
        override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            receivedURLs.append(url)
           return stubs[url] ?? FakeURLSessionDataTask()
        }
   }
    
   
    private class FakeURLSessionDataTask: URLSessionDataTask{
        override func  resume(){}
    }
    
    private class URLSessionDataTaskSpy: URLSessionDataTask{
        var resumeCallCount = 0
        override func resume(){
            resumeCallCount += 1
        }
    }
    
}
