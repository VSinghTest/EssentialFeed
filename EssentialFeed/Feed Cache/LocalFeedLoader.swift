//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Vibha Singh on 2/21/21.
//
// Loading from the cache is a "Query", and ideally should have no side-effects.
// Deleting the cache alters the state of the system, which is a side-effect.

import Foundation
 
public final class LocalFeedLoader{
    
    private let store: FeedStore
    private let currentDate: () -> Date
    private let calendar = Calendar(identifier: .gregorian)
    
    public typealias SaveResult = Error?
    public typealias LoadResult = LoadFeedResult
    
  public init(store: FeedStore, currentDate:@escaping () -> Date ){
        self.store = store
        self.currentDate = currentDate
    }
    
    
    private var maxCacheAgeInDays: Int{
        return 7
    }
    
    private func validate(_ timestamp: Date) -> Bool{
        guard let maxCacheAge = calendar.date(byAdding: .day,value: maxCacheAgeInDays, to: timestamp) else{ return false }
        return currentDate() < maxCacheAge
    }
    
    
    
}


extension LocalFeedLoader{
    
    public func save( _ feed: [FeedImage], completion: @escaping(SaveResult) -> Void){
          
          store.deleteCachedFeed{ [weak self] error in
              guard let self = self else{ return }
              
              if let cacheDeletionError = error{
                  completion(cacheDeletionError)
              }else{
                  self.cache(feed, with: completion)
                  }
                  
              }
          }
    
    
    private func cache( _ feed: [FeedImage], with completion: @escaping (SaveResult) -> Void){
        store.insert(feed.toLocal(), timestamp: self.currentDate()){ [weak self] error in
            guard self != nil else{ return }
            completion(error)
        }
    }
}
  
   
    
extension LocalFeedLoader: FeedLoader{
    
    public func load(completion: @escaping (LoadResult) -> Void){
        store.retrieve(){ [weak self] result in
            
            guard let self = self else { return }
            
            switch result{
            case let .failure(error):
            
                completion(.failure(error))
           
            case let .found(feed, timestamp) where self.validate(timestamp):
                completion(.success(feed.toModels()))
            
            case .found, .empty:
                completion(.success([]))
            }
            
        }
    }
}

extension LocalFeedLoader{
    public func validateCache(){
        store.retrieve { [weak self] result  in
            guard let self = self else { return }
            
            switch result{
            case .failure:
                self.store.deleteCachedFeed{_ in }
                
            case let .found(_ , timestamp) where !self.validate(timestamp):
                self.store.deleteCachedFeed{ _ in }
                
            case .empty, .found: break
                
                
                //By using explicit "cases" instead of "default", we get a build error when a new case is added to the enum.
            
                // A build error can be useful as it will remind us to rethink the validation logic( maybe a new case should also trigger a cache deletion!), but it makes our code less flexible ( susceptible to breaking changes). It's a trade off.
            
                // Alternatively, you can add, along with the explicit cases, "@unknown deafult" which will generate a warning (rather than a build error) whne new cases are added.
            }
        }
       
    }
}
   

private extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage]{
        return map{ LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)}
    }
}


private extension Array where Element == LocalFeedImage {
    func toModels() -> [FeedImage]{
        return map{ FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)}
    }
}




