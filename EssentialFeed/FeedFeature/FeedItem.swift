//
//  FeedItem.swift
//  EssentialFeed
//
//  Created by Vibha Singh on 2/7/21.
//

import Foundation

public struct FeedItem: Equatable {
    
    public let id: UUID
    public let description: String?
    public let location: String?
    public let imageUrl:   URL
    
    
    public init(id: UUID, description: String?, location: String?, imageUrl: URL){
        self.id = id
        self.description = description
        self.location = location
        self.imageUrl = imageUrl
    }
}


// Red Flag !!!!! APi detail leaked into our feature module
// A seemingly harmless string in the wrong module can end up breaking our abstractions!!
// Move decodable logic to a new private item struct to decouple the feed feature module
//from API Implementaion details
