//
//  U RLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Vibha Singh on 2/13/21.
//

import XCTest
import EssentialFeed


class URLSessionHTTPClientTests: XCTestCase {
    
    override func setUp() {
        URLProtocolStub.startInterceptingRequests()
    }

    override func tearDown() {
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
        
        let requestError = anyNSError()
        
        let receivedError = resultErrorFor(data: nil, response: nil, error: requestError)
        
        XCTAssertEqual(receivedError as NSError?, requestError)
    }
    
    
    func test_getFromURL_failsOnAllInvalidRepresentationCases(){
        
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: nil))
   
    }
    
    func test_getFromURL_succeedOnHTTPURLResponseWithData(){
        
        let data = anyData()
        let response = anyHTTPURLResponse()
       
        let recivedValues = resultValuesFor(data: data, response:response, error: nil)
        
        XCTAssertEqual(recivedValues?.data, data)
        XCTAssertEqual(recivedValues?.response.url, response.url)
        XCTAssertEqual(recivedValues?.response.statusCode, response.statusCode)
  
    }
    
    func test_getFromURL_succeedWithEmptyDataOnHTTPURLResponseWithNilData(){
        
        let response = anyHTTPURLResponse()
        let recivedValues = resultValuesFor(data: nil, response:response, error: nil)
        
        let emptyData = Data()
        
        XCTAssertEqual(recivedValues?.data, emptyData)
        XCTAssertEqual(recivedValues?.response.url, response.url)
        XCTAssertEqual(recivedValues?.response.statusCode, response.statusCode)
    }
    
    
    
    
//MARK: - Helpers
    
    
    // Move the URLSessionHTTPClient( the system under test, or "SUT") creation to a factory method to protect our tests from breaking changes.
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> HTTPClient{
        let sut = URLSessionHTTPClient()
       // trackForMemoryLeaks(instance: sut, file: file, line: line) No use of it now: shared instance never go away
        return sut
    }
    
    private func resultValuesFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #filePath, line: UInt = #line) -> (data:Data, response: HTTPURLResponse)?{
       
        let result = resultFor(data: data, response: response, error: error)
        
        switch result{
        case let .success(response, data):
                return (data, response)
        default:
                XCTFail("Expected success, got \(result) instead", file: file, line: line)
                return nil
    }
       
}
    
    private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #filePath, line: UInt = #line) -> Error?{
        
        let result = resultFor(data: data, response: response, error: error)
            switch result{
            case let .failure(error):
                return error
            default:
                XCTFail("Expected failure, got \(result) instead", file: file, line: line)
                return nil
            }
    }
    
    private func resultFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #filePath, line: UInt = #line) -> HTTPClientResult?{
        
        URLProtocolStub.stub(data: data, response: response, error: error)
        let exp = expectation(description: "Wait for completion")
        let sut = makeSUT(file: file, line: line)
       
        var receivedResult: HTTPClientResult!
        sut.get(from: anyURL()){ result in
            receivedResult = result
            exp.fulfill()
            }
        
        wait(for: [exp], timeout: 1.0)
        return receivedResult
    }
    
    
    
    
    
    private func anyURL() -> URL{
       return  URL(string: "http://any-url.com")!
    }
   
    private func anyData() -> Data{
         Data("any data".utf8)
    }
    
    private func anyNSError() -> NSError{
        NSError(domain: "any error", code: 0)
    }
    
    private func nonHTTPURLResponse() -> URLResponse{
        URLResponse(url: anyURL(), mimeType: nil, expectedContentLength:0 , textEncodingName: nil)
     }
    
    private func anyHTTPURLResponse() -> HTTPURLResponse{
        HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
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
