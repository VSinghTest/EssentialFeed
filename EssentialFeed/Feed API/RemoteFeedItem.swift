//
//  RemoteFeedItem.swift
//  EssentialFeed
//
//  Created by Vibha Singh on 2/21/21.
//

import Foundation

internal struct RemoteFeedItem: Decodable{
      
    internal let id: UUID
    internal let description: String?
    internal let location: String?
    internal let image: URL
}
