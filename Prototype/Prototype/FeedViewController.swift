//
//  FeedViewController.swift
//  Prototype
//
//  Created by Vibha Singh on 2/27/21.
//

import UIKit

final class FeedViewController: UITableViewController{
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return self.tableView.dequeueReusableCell(withIdentifier: "FeedImageCell")!
        }
}

