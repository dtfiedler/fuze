//
//  FirstViewController.swift
//  SoundFuze
//
//  Created by Dylan Fiedler on 10/23/15.
//  Copyright © 2015 xor. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController, SPTAudioStreamingPlaybackDelegate {
    
    var window: UIWindow?
    
    let kClientID = "db5f7f0e54ed4342b9de8cc08ddcc29b"
    let kCallbackURL = "soundfuze://"
    let kTokenSwapURL = "http://localhost:1234/swap"
    let kTokenRefreshURL = "http://localhost:1234/refresh"
    
    
    var player: SPTAudioStreamingController?
    let auth = SPTAuth.defaultInstance()
    var session: SPTSession?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
                        self.playUsingSession(newsession)
                        
                    } else {
                        print("error refreshing new spotify session")
                    }
                })
            } else {
                print("session valid")
                
                playUsingSession(session)
            }
        } else {
            print("here")
        }
    }
    
    
    func playUsingSession(session: SPTSession){
        if (player == nil){
            player = SPTAudioStreamingController(clientId: kClientID)
        }
        
        player?.loginWithSession(session, callback: {(error: NSError!) -> Void in
            if error != nil {
                print("Playback error: \(error.description)")
                return
            }
        })
        
        SPTRequest.requestItemAtURI(NSURL(string: "spotify:track:1WJk986df8mpqpktoktlce"), withSession: session, callback: {(error: NSError!, trackObj: AnyObject?) -> Void in
            if (error != nil){
                print("track lookup got error: \(error)")
                return
            }
            
            let track = trackObj as! SPTTrack
            self.player?.playTrackProvider(track, callback: nil)
        })
        
    }



        
        func addSong(sender: AnyObject){
            
        }

}

