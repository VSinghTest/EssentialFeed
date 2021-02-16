//
//  U RLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Vibha Singh on 2/13/21.
//

import XCTest
import EssentialFeed




class URLSessionHTTPClient{
    
    private let session: URLSession
    
    init(session: URLSession = .shared){
        self.session = session
    }
    
    struct UnexpectedValuesRepresentation: Error{}
    
    func get(from url: URL , completion: @escaping(HTTPClientResult) -> Void){
        
        session.dataTask(with: url){ data, response, error in
            if  let error = error {
                completion(.failure(error))
            }else{
                completion(.failure(UnexpectedValuesRepresentation()))
            }
        }.resume()
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    
    override func setUp() {
        URLProtocolStub.startInterceptingRequests()
    }

    override class func tearDown() {
        URLProtocolStub.stopInterceptingRequests()
    }
    func test_getFromURL_performGETRequestWithURL(){
        
       
        let url = anyURL()
        let exp = expectation(description: "Wait for request")
        URLProtocolStub.observeRequests{
            request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        makeSUT().get(from: url){_ in }
        wait(for: [exp], timeout: 1.0)
       
    }
    
    func test_getFromURL_failsOnRequestError(){
        
        let error = NSError(domain: "a error", code: 0)
        
        let exp = expectation(description: "Wait for completion")
        
        URLProtocolStub.stub(data: nil, response: nil, error: error)
        makeSUT().get(from: anyURL()){
            result in
            
            switch result{
            
            case let .failure(receivedError as NSError):
                XCTAssertEqual(receivedError, error)
            default:
                XCTFail("Expected failure with error \(error), got \(result) instead")
            }
            
            exp.fulfill()
    }
        wait(for: [exp], timeout: 1.0)
        
        
    }
    
    
    func test_getFromURL_failsOnAllNilValues(){
        
       
        URLProtocolStub.stub(data: nil, response: nil, error: nil)
        let exp = expectation(description: "Wait for completion")
        
        
        makeSUT().get(from: anyURL()){
            result in
            
            switch result{
            
            case .failure:
                break
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
            
            exp.fulfill()
    }
        wait(for: [exp], timeout: 1.0)
        
        
    }
    
    
//MARK: - Helpers
    
    
    // Move the URLSessionHTTPClient( the system under test, or "SUT") creation to a factory method to protect our tests from breaking changes.
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> URLSessionHTTPClient{
        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(instance: sut, file: file, line: line)
        return sut
    }
    
    private func anyURL() -> URL{
       return  URL(string: "http://any-url.com")!
    }
   
    private class URLProtocolStub: URLProtocol{
       
        private static var stub: Stub?
        private static var requestObserver:((URLRequest) -> Void)?
        private struct Stub{
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        static func stub( data: Data?, response: URLResponse?, error: Error? ){
            
            stub = Stub(data: data, response: response, error: error)
        }
        
        static func observeRequests(observer: @escaping (URLRequest) -> Void){
            requestObserver = observer
        }
        
        static func startInterceptingRequests(){
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequests(){
            URLProtocol.unregisterClass(URLProtocolStub.self)
            requestObserver = nil
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            requestObserver?(request)
            return true
        }
    
    
        override class func canonicalRequest(for request: URLRequest) -> URLRequest{
            return request
        }
    
    override func startLoading(){
       
        guard let stub = URLProtocolStub.stub else{ return }
        
        if let data = stub.data {
            client?.urlProtocol(self, didLoad: data)
        }
        
        if let response = stub.response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
            if let error = stub.error{
                client?.urlProtocol(self, didFailWithError: error)
                
            }
        client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {
            
        }
    }

}
