//
//  LoginViewController.swift
//  SoundFuze
//
//  Created by Dylan Fiedler on 10/23/15.
//  Copyright © 2015 xor. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, SPTAuthViewDelegate, SPTAudioStreamingPlaybackDelegate {
    
    var window: UIWindow?
    
    let kClientID = "db5f7f0e54ed4342b9de8cc08ddcc29b"
    let kCallbackURL = "soundFuze://"
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
        
        if let sessionObj : AnyObject = NSUserDefaults.standardUserDefaults().objectForKey("spotifySession") {
            
            let sessionDataObj : NSData = sessionObj as! NSData
            let session = NSKeyedUnarchiver.unarchiveObjectWithData(sessionDataObj) as! SPTSession
            
            if !session.isValid() {
                
                SPTAuth.defaultInstance().renewSession(session, callback: { (error : NSError!, newsession : SPTSession!) -> Void in
                    
                    let sessionData = NSKeyedArchiver.archivedDataWithRootObject(session)
                    userDefaults.setObject(sessionData, forKey: "SpotifySession")
                    userDefaults.synchronize()
                    
                    self.session = newsession
                    self.updateAfterFirstLogin()
                    
                })
            }else{
                
                print("error refreshing new spotify session")
                
            }
            
        }else{
            updateAfterFirstLogin()
            
        }
        
    }
    func updateAfterFirstLogin(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let tabVC = storyboard.instantiateViewControllerWithIdentifier("tabVC") as! UITabBarController
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.window?.rootViewController = tabVC
    }
    
//    override func viewDidAppear(animated: Bool) {
//        if spotifyAuthenticator.session.isValid(){
//            //self.performSegueWithIdentifier("login", sender: self)
//        }
//    }


        // Dispose of any resources that can be recreated.
        
        @IBAction func loginWithSpotify(sender: AnyObject) {
            
            let spotifyAuth = SPTAuth.defaultInstance()
            spotifyAuth.clientID = kClientID
            spotifyAuth.redirectURL = NSURL(string: kCallbackURL)
            spotifyAuth.requestedScopes = [SPTAuthStreamingScope]
            
            let spotifyLoginUrl : NSURL = spotifyAuth.loginURL
            
            UIApplication.sharedApplication().openURL(spotifyLoginUrl)

            
//           
//            spotifyAuthenticator.clientID = kClientID
//            spotifyAuthenticator.requestedScopes = [SPTAuthStreamingScope]
//            spotifyAuthenticator.redirectURL = NSURL(string: kCallbackURL)
//            spotifyAuthenticator.tokenSwapURL = NSURL(string: kTokenSwapURL)
//            spotifyAuthenticator.tokenRefreshURL = NSURL(string: kTokenRefreshURL)
//            
//            let spotifyAuthenticationViewController = SPTAuthViewController.authenticationViewController()
//            spotifyAuthenticationViewController.delegate = self
//            spotifyAuthenticationViewController.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
//            spotifyAuthenticationViewController.definesPresentationContext = true
//            presentViewController(spotifyAuthenticationViewController, animated: false, completion: nil)
//
            
        }
    
        
        // SPTAuthViewDelegate protocol methods

        func authenticationViewController(authenticationViewController: SPTAuthViewController!, didLoginWithSession session: SPTSession!) {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let tabController = storyboard.instantiateViewControllerWithIdentifier("tabController") as! UITabBarController
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            appDelegate.window?.rootViewController = tabController
        }
    
        func authenticationViewControllerDidCancelLogin(authenticationViewController: SPTAuthViewController!) {
            print("login cancelled")
        }
        
        func authenticationViewController(authenticationViewController: SPTAuthViewController!, didFailToLogin error: NSError!) {
            print("login failed")
        }
    
        // SPTAudioStreamingPlaybackDelegate protocol methods

        private
        
        func setupSpotifyPlayer() {
            player = SPTAudioStreamingController(clientId: kClientID) // can also use kClientID; they're the same value
            player!.playbackDelegate = self
            player!.diskCache = SPTDiskCache(capacity: 1024 * 1024 * 64)
        }
    
        func loginWithSpotifySession(session: SPTSession) {
            player!.loginWithSession(session, callback: { (error: NSError!) in
                if error != nil {
                    print("Couldn't login with session: \(error)")
                    return
                }
                self.useLoggedInPermissions()
            })
            
            self.performSegueWithIdentifier("login", sender: self)
        }
        
        func useLoggedInPermissions() {
            let spotifyURI = "spotify:track:1WJk986df8mpqpktoktlce"
            player!.playURIs([NSURL(string: spotifyURI)!], withOptions: nil, callback: nil)
        }

}