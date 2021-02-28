//
//  FeedViewController.swift
//  Prototype
//
//  Created by Vibha Singh on 2/27/21.
//

import UIKit


struct FeedImageViewModel {
    let description: String?
    let location: String?
    let imageName: String
}
final class FeedViewController: UITableViewController{
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return self.tableView.dequeueReusableCell(withIdentifier: "FeedImageCell")!
        }
}

