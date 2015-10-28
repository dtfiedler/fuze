//
//  SecondViewController.swift
//  SoundFuze
//
//  Created by Dylan Fiedler on 10/23/15.
//  Copyright © 2015 xor. All rights reserved.
//

import UIKit

class SecondViewController: UIViewController, UISearchControllerDelegate {
    
    var spoitfySearch: SPTSearch?
    
    var results = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //SPTSearch.createRequestForSearchWithQuery("jackson", queryType: SPTSearchQueryType.QueryTypeArtist, accessToken: nil)
        SPTSearch.performSearchWithQuery("jackson", queryType: SPTSearchQueryType.QueryTypeArtist, accessToken: nil, callback: nil)
        
    
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        return cell
    }

}

