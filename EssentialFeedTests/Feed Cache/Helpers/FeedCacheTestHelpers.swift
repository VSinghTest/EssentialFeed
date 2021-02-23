//
//  FeedCacheTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Vibha Singh on 2/22/21.
//

import Foundation
import EssentialFeed



 func uniqueImage() -> FeedImage{
    return FeedImage(id: UUID(), description: "unique Item", location: nil, url: anyURL())
}


 func uniqueImageFeed() -> (models:[FeedImage], local: [LocalFeedImage]){
    let models = [uniqueImage(), uniqueImage()]
    let local = models.map{ LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)
    }
    return (models,local)
}


 extension Date{
    
    func minusFeedCacheMaxAge() -> Date{  // Single source of truth for expiration days
        return adding(days: -feedCacheMaxAgeInDays)
    }
    
    private var feedCacheMaxAgeInDays: Int {
        return 3
    }
    
    private func adding(days: Int) -> Date{
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
 }

extension Date{
    func adding(seconds: TimeInterval) -> Date{
        return self + seconds
    }
}

