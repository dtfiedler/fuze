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
    var artists: [SPTPartialArtist] = []
    var albums: [SPTPartialAlbum] = []
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchTable: UITableView!
    var queryType: SPTSearchQueryType!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.searchTable.delegate = self
        self.searchTable.dataSource = self
        self.searchBar.delegate = self
        self.searchTable.estimatedRowHeight = 67
        queryType = SPTSearchQueryType.QueryTypeTrack

        let userDefaults = NSUserDefaults.standardUserDefaults()
        if let sessionObj : AnyObject = NSUserDefaults.standardUserDefaults().objectForKey("SpotifySession") {
            
            let sessionDataObj : NSData = sessionObj as! NSData
            self.session = NSKeyedUnarchiver.unarchiveObjectWithData(sessionDataObj) as! SPTSession
            
            if !self.session!.isValid() {
                
                SPTAuth.defaultInstance().renewSession(session,  callback: { (error : NSError!, newsession : SPTSession!) -> Void in
                    
                    if error == nil {
                        
                        let sessionData = NSKeyedArchiver.archivedDataWithRootObject(self.session!)
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
    
    @IBAction func indexChanged(sender:UISegmentedControl){
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            queryType = SPTSearchQueryType.QueryTypeTrack
            break
        case 1:
            queryType  = SPTSearchQueryType.QueryTypeArtist
            break
        case 2:
            queryType = SPTSearchQueryType.QueryTypeAlbum
            break
        default:
            queryType = SPTSearchQueryType.QueryTypeTrack
            break
        }
        search()
        self.searchTable.reloadData()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView:UITableView, numberOfRowsInSection section:Int) -> Int {
        switch (segmentedControl.selectedSegmentIndex){
        case 0:
            return self.results.count
            break
        case 1:
            return self.artists.count
            break
        case 2:
            return self.albums.count
            break
        default:
            return self.results.count
            break
        }
    }
    
    func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("track", forIndexPath: indexPath) as! TrackTableViewCell
        cell.accessoryType = UITableViewCellAccessoryType.None
        
        if (indexPath.row <= self.results.count){
            
            
            switch (segmentedControl.selectedSegmentIndex){
            case 0:
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
                break
                
            case 1:
                let artist = self.artists[indexPath.row] as! SPTArtist
                cell.trackName.text = artist.name
                cell.artist.text = ""
                
                if let albumImage: SPTImage? = artist.smallestImage as SPTImage {
                    if let image = albumImage!.imageURL.description as? String {
                        if let imageData: NSData? = NSData(contentsOfURL: NSURL(string: image)!) {
                            
                            cell.albumArtwork.image = UIImage(data: imageData!)
                        }
                    }
                }

                break
            default:
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
                break
            }
            
        }

    
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.searchBar.resignFirstResponder()
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        if (cell!.accessoryType == UITableViewCellAccessoryType.None){
            cell!.accessoryType = UITableViewCellAccessoryType.Checkmark
            //cell!.backgroundColor = UIColor.lightGrayColor()
        } else {
            cell!.accessoryType = UITableViewCellAccessoryType.None
            //cell!.backgroundColor = UIColor.clearColor()
        }
        
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
        
        

    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        self.searchBar.resignFirstResponder()
        search()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {

        //search()

    }
    
    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {
        return true
    }

    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
    }
    
    func searchDisplayControllerDidBeginSearch(controller: UISearchDisplayController) {
        sleep(2)
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        print("cancel selected")
    }
    
    func search(){
        self.results.removeAll()
        self.searchTable.reloadData()
        self.artists.removeAll()
        self.albums.removeAll()
        let searchText: String! = self.searchBar.text
        
        if (!searchText.isEmpty) {
            SPTRequest.performSearchWithQuery(searchText, queryType: queryType, offset: 0, session: self.session, callback: {(error: NSError!, result: AnyObject?) -> Void in
                if (error != nil){
                    print("Error searching: \(error)")
                    return
                }
                let trackListPage = result as! SPTListPage
                
                if (self.queryType == SPTSearchQueryType.QueryTypeTrack){
                    
                    for item in trackListPage.items {
                        if (!self.results.contains(item as! SPTPartialTrack)){
                            self.results.append(item as! SPTPartialTrack)
                        }
                    }
                    self.searchTable.reloadData()
                } else if (self.queryType == SPTSearchQueryType.QueryTypeArtist){
                    for item in trackListPage.items{
                        self.artists.append(item as! SPTPartialArtist)
                    }
                } else if (self.queryType == SPTSearchQueryType.QueryTypeAlbum){
                    for item in trackListPage.items{
                        self.albums.append(item as! SPTPartialAlbum)
                    }
                }
                
            })
        }
        
        self.searchTable.reloadData()
        
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.searchBar.resignFirstResponder()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}

