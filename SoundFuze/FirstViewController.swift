//
//  FirstViewController.swift
//  SoundFuze
//
//  Created by Dylan Fiedler on 10/23/15.
//  Copyright © 2015 xor. All rights reserved.
//

import UIKit
import AVFoundation

class FirstViewController: UIViewController, SPTAudioStreamingPlaybackDelegate, UITableViewDataSource, UITableViewDelegate {
    
    var window: UIWindow?
    
    @IBOutlet weak var trackTable: UITableView!
    
    let kClientID = "db5f7f0e54ed4342b9de8cc08ddcc29b"
    let kCallbackURL = "soundfuze://"
    let kTokenSwapURL = "http://localhost:1234/swap"
    let kTokenRefreshURL = "http://localhost:1234/refresh"
    
    
    var player: SPTAudioStreamingController?
    let auth = SPTAuth.defaultInstance()
    var session: SPTSession?
    
    var queuedTracks: [SPTTrack] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.trackTable.delegate = self
        self.trackTable.dataSource = self
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: ":updateAfterFirstlogin", name: "spotifyLoginSuccesfull", object: nil)
        // Do any additional setup after loading the view
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if let sessionObj : AnyObject = NSUserDefaults.standardUserDefaults().objectForKey("SpotifySession") {
            
            let sessionDataObj : NSData = sessionObj as! NSData
            let session = NSKeyedUnarchiver.unarchiveObjectWithData(sessionDataObj) as! SPTSession
            
            if !session.isValid() {
                
                SPTAuth.defaultInstance().renewSession(session, withServiceEndpointAtURL: NSURL(string: kTokenRefreshURL), callback: { (error : NSError!, newsession : SPTSession!) -> Void in
                    
                    if error == nil {
                        
                        let sessionData = NSKeyedArchiver.archivedDataWithRootObject(session)
                        userDefaults.setObject(sessionData, forKey: "SpotifySession")
                        userDefaults.synchronize()
                        
                        self.session = newsession
                        //self.playUsingSession(newsession)
                        
                    } else {
                        print("error refreshing new spotify session")
                    }
                })
            } else {
                print("session valid")
                
                //add track to queue
                SPTRequest.requestItemAtURI(NSURL(string: "spotify:track:1WJk986df8mpqpktoktlce"), withSession: session, callback: {(error: NSError!, trackObj: AnyObject?) -> Void in
                    if (error != nil){
                        print("track lookup got error: \(error)")
                        return
                    }
                    
                    let track = trackObj as! SPTTrack
                    self.queuedTracks.append(track)
                    self.trackTable.reloadData()
                    //self.player?.playTrackProvider(track, callback: nil)
                })
                
            }
        } else {
            print("here")
        }
    }
    
    
    func playUsingSession(session: SPTSession, trackIndex: Int){
        if (player == nil){
            player = SPTAudioStreamingController(clientId: kClientID)
        }
        
        player?.loginWithSession(session, callback: {(error: NSError!) -> Void in
            if error != nil {
                print("Playback error: \(error.description)")
                return
            }
        })
        print("play")
        self.player?.playTrackProvider(queuedTracks[trackIndex], callback: nil)
        
//        SPTRequest.requestItemAtURI(NSURL(string: "spotify:track:1WJk986df8mpqpktoktlce"), withSession: session, callback: {(error: NSError!, trackObj: AnyObject?) -> Void in
//            if (error != nil){
//                print("track lookup got error: \(error)")
//                return
//            }
//            
//            let track = trackObj as! SPTTrack
//            //self.queuedTracks.append(track)
//            //self.trackTable.reloadData()
//            self.player?.playTrackProvider(track, callback: nil)
//        })
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return queuedTracks.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        print("selected track")
        
        let cell = tableView.dequeueReusableCellWithIdentifier("track", forIndexPath: indexPath) as! TrackTableViewCell
        
        cell.trackName.text = queuedTracks[indexPath.row].name
        let artistInfo = queuedTracks[indexPath.row].artists.first!.name
        cell.artist.text = artistInfo
        
        let albumImage = queuedTracks[indexPath.row].album.covers.first as! SPTImage
        let image = albumImage.imageURL.description
        let imageData = NSData(contentsOfURL: NSURL(string: image)!)
        
        cell.albumArtwork.image = UIImage(data: imageData!)
        
        return cell
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! TrackTableViewCell
        
        if (cell.backgroundColor != UIColor.lightGrayColor()){
            cell.backgroundColor = UIColor.lightGrayColor()
            
            let userDefaults = NSUserDefaults.standardUserDefaults()
            
            if let sessionObj : AnyObject = NSUserDefaults.standardUserDefaults().objectForKey("SpotifySession") {
                
                let sessionDataObj : NSData = sessionObj as! NSData
                let session = NSKeyedUnarchiver.unarchiveObjectWithData(sessionDataObj) as! SPTSession
                
                if !session.isValid() {
                    
                    SPTAuth.defaultInstance().renewSession(session, withServiceEndpointAtURL: NSURL(string: kTokenRefreshURL), callback: { (error : NSError!, newsession : SPTSession!) -> Void in
                        
                        if error == nil {
                            
                            let sessionData = NSKeyedArchiver.archivedDataWithRootObject(session)
                            userDefaults.setObject(sessionData, forKey: "SpotifySession")
                            userDefaults.synchronize()
                            
                            self.session = newsession
                            self.playUsingSession(newsession, trackIndex: indexPath.row)
                            
                        } else {
                            print("error refreshing new spotify session")
                        }
                    })
                } else {
                    print("session valid")
                    playUsingSession(session, trackIndex: indexPath.row)
                    self.trackTable.reloadData()
                }
            }
        } else {
            player?.stop({(error: NSError!) -> Void in
                if (error != nil){
                    print("Cannot stop playback: \(error)")
                }
            })
            cell.backgroundColor = UIColor.clearColor()
            self.trackTable.reloadData()
        }
 
        self.trackTable.deselectRowAtIndexPath(indexPath, animated: false)
        
    }

    func addSong(sender: AnyObject){
            
    }

}

