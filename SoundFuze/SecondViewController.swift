//
//  SecondViewController.swift
//  SoundFuze
//
//  Created by Dylan Fiedler on 10/23/15.
//  Copyright © 2015 xor. All rights reserved.
//

import UIKit

class SecondViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchDisplayDelegate {
    
    var spotifySearch: SPTSearch!
    var session: SPTSession?
    var results: [SPTPartialTrack] = []
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.searchTable.delegate = self
        self.searchTable.dataSource = self
        self.searchBar.delegate = self
        self.searchTable.estimatedRowHeight = 67

        let userDefaults = NSUserDefaults.standardUserDefaults()
        if let sessionObj : AnyObject = NSUserDefaults.standardUserDefaults().objectForKey("SpotifySession") {
            
            let sessionDataObj : NSData = sessionObj as! NSData
            let session = NSKeyedUnarchiver.unarchiveObjectWithData(sessionDataObj) as! SPTSession
            
            if !session.isValid() {
                
                SPTAuth.defaultInstance().renewSession(session,  callback: { (error : NSError!, newsession : SPTSession!) -> Void in
                    
                    if error == nil {
                        
                        let sessionData = NSKeyedArchiver.archivedDataWithRootObject(session)
                        userDefaults.setObject(sessionData, forKey: "SpotifySession")
                        userDefaults.synchronize()
                        self.session = newsession
                        
                    } else {
                        print("error refreshing new spotify session")
                    }
                })
            } else {
                print("session valid")
                
            }
        } else {
            print("here")
        }
    
        self.searchTable.reloadData()
    
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView:UITableView, numberOfRowsInSection section:Int) -> Int {
        return self.results.count
    }
    
    func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
                let cell = tableView.dequeueReusableCellWithIdentifier("track", forIndexPath: indexPath) as! TrackTableViewCell
        
                if (indexPath.row <= self.results.count){
                    let resultOption = self.results[indexPath.row]
                    cell.trackName.text = resultOption.name
                    cell.artist.text = resultOption.artists.first!.name
                    
                    if let albumImage: SPTImage? = resultOption.album.covers.first as! SPTImage {
                        if let image = albumImage!.imageURL.description as? String {
                            if let imageData: NSData? = NSData(contentsOfURL: NSURL(string: image)!) {
                
                                cell.albumArtwork.image = UIImage(data: imageData!)
                            }
                        }
                    }


                }

    
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let track = results[indexPath.row]
        SPTRequest.requestItemAtURI(track.uri, withSession: nil, callback: {(error: NSError!, trackObj: AnyObject?) ->  Void in
                    if (error != nil){
                            print("track lookup got error: \(error)")
                            return
                    }
                                    print("track found")
            
                                    let track = trackObj as! SPTTrack
                                        NSNotificationCenter.defaultCenter().postNotificationName("addToQueue", object: nil, userInfo: ["track": track, "user": UIDevice.currentDevice().name])
                })
                            self.searchTable.reloadData()

    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
         NSNotificationCenter.defaultCenter().postNotificationName("closeMenu", object: nil)
        self.searchBar.resignFirstResponder()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String?) {
        self.results.removeAll()
        self.searchTable.reloadData()
        if ((searchText?.isEmpty) == false) {
        SPTRequest.performSearchWithQuery(self.searchBar.text, queryType: SPTSearchQueryType.QueryTypeTrack, offset: 0, session: nil, callback: {(error: NSError!, result: AnyObject?) -> Void in
            if (error != nil){
                print("Error searching: \(error)")
                return
            }
            let trackListPage = result as! SPTListPage
            
            for item in trackListPage.items {
                if (!self.results.contains(item as! SPTPartialTrack)){
                    self.results.append(item as! SPTPartialTrack)
                    
                }
                }
            self.searchTable.reloadData()
            
        })
        }
    }
    
    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {
        return true
    }

    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
    }
    
    func searchDisplayControllerDidBeginSearch(controller: UISearchDisplayController) {
        sleep(2)
    }
}

