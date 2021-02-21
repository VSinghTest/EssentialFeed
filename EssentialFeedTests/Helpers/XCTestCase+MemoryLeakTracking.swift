//
//  XCTestCase+MemoryLeakTracking.swift
//  EssentialFeedTests
//
//  Created by Vibha Singh on 2/16/21.
//

import XCTest

extension XCTestCase {

     func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line ){
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated. Potential Memory Leak", file: file, line: line)
        }
    }
}
