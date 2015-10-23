//
//  LoginViewController.swift
//  SoundFuze
//
//  Created by Dylan Fiedler on 10/23/15.
//  Copyright © 2015 xor. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, SPTAuthViewDelegate, SPTAudioStreamingPlaybackDelegate {
    
    let kClientID = "db5f7f0e54ed4342b9de8cc08ddcc29b"
    let kCallbackURL = "soundFuze://"
    let kTokenSwapURL = "http://localhost:1234/swap"
    let kTokenRefreshURL = "http://localhost:1234/refresh"
    
    var player: SPTAudioStreamingController?
    let spotifyAuthenticator = SPTAuth.defaultInstance()
   
    override func viewDidLoad() {
        super.viewDidLoad()
        //UIApplication.sharedApplication().openURL(NSURL(string: "soundFuze://login")!)

        // Do any additional setup after loading the view.
    }


        // Dispose of any resources that can be recreated.
        
        @IBAction func loginWithSpotify(sender: AnyObject) {
            spotifyAuthenticator.clientID = kClientID
            spotifyAuthenticator.requestedScopes = [SPTAuthStreamingScope]
            spotifyAuthenticator.redirectURL = NSURL(string: kCallbackURL)
            spotifyAuthenticator.tokenSwapURL = NSURL(string: kTokenSwapURL)
            spotifyAuthenticator.tokenRefreshURL = NSURL(string: kTokenRefreshURL)
            

            let spotifyAuthenticationViewController = SPTAuthViewController.authenticationViewController()
            spotifyAuthenticationViewController.delegate = self
            spotifyAuthenticationViewController.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
            spotifyAuthenticationViewController.definesPresentationContext = true
            presentViewController(spotifyAuthenticationViewController, animated: false, completion: nil)

        
        }
        
        // SPTAuthViewDelegate protocol methods

        func authenticationViewController(authenticationViewController: SPTAuthViewController!, didLoginWithSession session: SPTSession!) {
            //setupSpotifyPlayer()
            //loginWithSpotifySession(session)
            print("login successful")
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
            player = SPTAudioStreamingController(clientId: spotifyAuthenticator.clientID) // can also use kClientID; they're the same value
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