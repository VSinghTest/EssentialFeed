//
//  LocalFeedItem.swift
//  EssentialFeed
//
//  Created by Vibha Singh on 2/21/21.
//

import Foundation

public struct LocalFeedItem: Equatable {
    
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