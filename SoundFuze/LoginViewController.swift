//
//  LoginViewController.swift
//  SoundFuze
//
//  Created by Dylan Fiedler on 10/23/15.
//  Copyright © 2015 xor. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, /*SPTAuthViewDelegate, */SPTAudioStreamingPlaybackDelegate{
    
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
       
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateAfterFirstlogin", name: "spotifyLoginSuccesfull", object: nil)
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
                        self.updateAfterFirstLogin()
    
                } else {
                    print("error refresh ing new spotify session")
                }
            })
            } else {
                print("session valid")
                updateAfterFirstLogin()
            }
        } else {
            print("here")
            
        }
    }
    
    func updateAfterFirstLogin(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let tabVC = storyboard.instantiateViewControllerWithIdentifier("tabVC") as! UITabBarController
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.window?.rootViewController = tabVC
    }
    

        // Dispose of any resources that can be recreated.
        
    @IBAction func loginWithSpotify(sender: AnyObject) {
        
        let spotifyAuth = SPTAuth.defaultInstance()
        let loginURL = spotifyAuth.loginURLForClientId(kClientID, declaredRedirectURL: NSURL(string: kCallbackURL), scopes: [SPTAuthStreamingScope])
        
        UIApplication.sharedApplication().openURL(loginURL)
        
    }

}