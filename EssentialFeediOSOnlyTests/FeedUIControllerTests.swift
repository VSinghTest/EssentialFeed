//

//
//  Created by Vibha Singh on 12/14/21.
//

import XCTest
import UIKit

final class FeedViewController: UIViewController{
    private var loader: FeedUIControllerTests.LoaderSpy?
    
    convenience init(loader: FeedUIControllerTests.LoaderSpy){
        
        self.init()
        self.loader = loader
    }
    
    override func viewDidLoad() {
        loader?.load()
    }
}

final class FeedUIControllerTests: XCTestCase {

    func test_init_doesNotLoadFeed(){
        let loader = LoaderSpy()
        let _ = FeedViewController(loader: loader)
        
        XCTAssertEqual(loader.loadFeedCallCount, 0)
    }
    
    func test_viewDidLoad_LoadFeeds(){
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)
        
        sut.loadViewIfNeeded()
        
        XCTAssertEqual(loader.loadFeedCallCount, 1)
    }
    
    
    
    class LoaderSpy{
        var loadFeedCallCount = 0
        func load(){
            loadFeedCallCount += 1
        }
        
    }
    
    
 
    
}
