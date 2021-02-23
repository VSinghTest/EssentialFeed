//
//  SharedTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Vibha Singh on 2/22/21.
//

import Foundation


func anyURL() -> URL{
  return  URL(string: "http://any-url.com")!
}

func anyNSError() -> NSError{
   NSError(domain: "any error", code: 0)
}
