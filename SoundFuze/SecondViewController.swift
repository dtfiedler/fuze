//
//  SecondViewController.swift
//  SoundFuze
//
//  Created by Dylan Fiedler on 10/23/15.
//  Copyright © 2015 xor. All rights reserved.
//

import UIKit

class SecondViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    var spoitfySearch: SPTSearch?
    var session: SPTSession?
    var results: [SPTTrack] = []
    
    @IBOutlet weak var searchTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.searchTable.delegate = self
        self.searchTable.dataSource = self

        let userDefaults = NSUserDefaults.standardUserDefaults()
        if let sessionObj : AnyObject = NSUserDefaults.standardUserDefaults().objectForKey("SpotifySession") {
            
            let sessionDataObj : NSData = sessionObj as! NSData
            let session = NSKeyedUnarchiver.unarchiveObjectWithData(sessionDataObj) as! SPTSession
            
            if !session.isValid() {
                
                //withServiceEndpointAtURL: NSURL(string: kTokenRefreshURL),
                
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

                SPTRequest.requestItemAtURI(NSURL(string: "spotify:track:1WJk986df8mpqpktoktlce"), withSession: session, callback: {(error: NSError!, trackObj: AnyObject?) ->          Void in
                        if (error != nil){
                            print("track lookup got error: \(error)")
                            return
                        }
                        print("track found")
    
                        let track = trackObj as! SPTTrack
                            self.results.append(track)
                            NSNotificationCenter.defaultCenter().postNotificationName("addToQueue", object: nil, userInfo: ["track": track])
                        })
                self.searchTable.reloadData()
                
            }
        } else {
            print("here")
        }
    
        self.searchTable.reloadData()
    
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(animated: Bool) {
        SPTRequest.requestItemAtURI(NSURL(string: "spotify:track:1WJk986df8mpqpktoktlce"), withSession: session, callback: {(error: NSError!, trackObj: AnyObject?) ->          Void in
            if (error != nil){
                print("track lookup got error: \(error)")
                return
            }
            print("track found")
            
            let track = trackObj as! SPTTrack
            self.results.append(track)
            NSNotificationCenter.defaultCenter().postNotificationName("addToQueue", object: nil, userInfo: ["track": track])
        })
        self.searchTable.reloadData()

    }
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView:UITableView!, numberOfRowsInSection section:Int) -> Int {
        return self.results.count
    }
    
    func tableView(tableView:UITableView!, cellForRowAtIndexPath indexPath:NSIndexPath!) -> UITableViewCell! {
                let cell = tableView.dequeueReusableCellWithIdentifier("track", forIndexPath: indexPath) as! TrackTableViewCell
        
                if (indexPath.row <= self.results.count){
                    let resultOption = self.results[indexPath.row]
                    cell.trackName.text = resultOption.name
                    cell.artist.text = resultOption.artists.first!.name
                    cell.imageView?.hidden = true
                }

    
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    



    

}

