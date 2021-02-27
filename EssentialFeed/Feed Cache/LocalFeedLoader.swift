//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Vibha Singh on 2/21/21.
//
// Loading from the cache is a "Query", and ideally should have no side-effects.
// Deleting the cache alters the state of the system, which is a side-effect.


// Localfeedloader implements Use cases (encapsulate application specific business logic) while collaborating with other types so LFL can be called a controller or a control boundary or interactor or model controller. controllers are not business models they communicate with b models to solve app specific b rules.By sepearcting these concepts b models, controllers and  frameworks is key to achieve modularity, freedom and testability. we keep separating app agnostic business rules eg policy from the app specific b logic like the controllers not just that but also seperating the app specific logic from concrete framework details. so, the feedstore protects our controller from depending on concrete store implementation like core data or realm or file system. you don't want framework dictating your architecture. you pugin your frameworks to solve infra details like storing data,making n/w request or updating the user interface so side-effects happen on the boundaries of the system eg storing something to the disk. we control the side-effects in the controller types that deals with impure functions and models as much as u can make tham deterministic and reusable across applications with no side effects or impure operations. at this stage, FeedImage is a model, just data.

// to fulfill the usecase its need to colloborate eg with a store type that we are hiding behind the feedstore interface, another app detail is how to get the current date also dealing with a synchrony those are all app details that is relevant to the core domain model these r just details

// caching policy is  a policy to a business rule ,dpending on the b rule this policy might be so imptt that needs to be shared among usecases and shared across spplication. so app agnostic. it all depends on the use case. In this case it's a business rule that can be used across usecases / application so can be encapsulate in its own model. we can reuse later if we have to. We can extract the b rules from this control type and moved it to the reusable model


// The localfeedloader should encapsulate application-speific logic only, and communicate with Modles to perform business logic.

// rules and policies (e.g. validation logic) are better suited in a domain model that is application-agnostic (so it can be [re]used across applications.

//Business models are normally separated into models that have identity and models that don't  have identity like policy. e.g. customer is a model and policy is a rule has not concept of identity.
//B rules with identity => entity (models with identity)
// values =>(models with no identity)  just encapsulates a rule that means we do't need instance of a feed cache policy.It can be static since this policy is deterministic has no side effects, hold no states

import Foundation

public final class LocalFeedLoader{
    
    private let store: FeedStore
    private let currentDate: () -> Date
   
  public init(store: FeedStore, currentDate:@escaping () -> Date ){
        self.store = store
        self.currentDate = currentDate
        
    }
 }


extension LocalFeedLoader{
    
    public typealias SaveResult = Error?
    
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
    
    public typealias LoadResult = FeedLoader.Result
    
    public func load(completion: @escaping (LoadResult) -> Void){
        
        store.retrieve(){ [weak self] result in
            guard let self = self else { return }
            
            switch result{
            case let .failure(error):
                completion(.failure(error))
           
            case let .found(feed, timestamp) where FeedCachePolicy.validate(timestamp, against: self.currentDate()):
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
                
            case let .found(_ , timestamp) where !FeedCachePolicy.validate(timestamp,against: self.currentDate()):
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




