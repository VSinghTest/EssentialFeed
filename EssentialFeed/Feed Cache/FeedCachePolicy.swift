//
//  FeedCachePolicy.swift
//  EssentialFeed
//
//  Created by Vibha Singh on 2/23/21.
//

import Foundation

internal final class FeedCachePolicy{
    
    private init() {}
    
  //  private let currentDate: () -> Date => impure fuction nondeterministic func so remove and provide through method injection
    private static let calendar = Calendar(identifier: .gregorian)
    
    
    private static var maxCacheAgeInDays: Int{
        return 3
    }
    
    static func validate(_ timestamp: Date, against date: Date) -> Bool{
        guard let maxCacheAge = calendar.date(byAdding: .day,value: maxCacheAgeInDays, to: timestamp) else{ return false }
        
        return date < maxCacheAge // this is a deterministic func
    }
    
}
