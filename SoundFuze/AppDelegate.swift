//
//  AppDelegate.swift
//  SoundFuze
//
//  Created by Dylan Fiedler on 10/23/15.
//  Copyright © 2015 xor. All rights reserved.
//

import UIKit
import AVFoundation

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    let session: SPTSession! = nil
    let kClientID = "db5f7f0e54ed4342b9de8cc08ddcc29b"
    let kCallbackURL = "soundfuze://"
    let kTokenSwapURL = "http://localhost:1234/swap"
    let kTokenRefreshURL = "http://localhost:1234/refresh"
    var loggedIn = false

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool{
        
        
        if (SPTAuth.defaultInstance().canHandleURL(url, withDeclaredRedirectURL: NSURL(string: kCallbackURL))) {

            SPTAuth.defaultInstance().handleAuthCallbackWithTriggeredAuthURL(url, tokenSwapServiceEndpointAtURL: NSURL(string: kTokenSwapURL), callback: {(error: NSError!, session: SPTSession!) -> Void in
                if error != nil {
                    print("Auth error : \(error.description)")
                    return
                }
                
                let userDefaults = NSUserDefaults.standardUserDefaults()
                let sessionData = NSKeyedArchiver.archivedDataWithRootObject(session!)
                userDefaults.setObject(sessionData, forKey: "SpotifySession")
                
                userDefaults.synchronize()
                
                NSNotificationCenter.defaultCenter().postNotificationName("loginSuccesfull", object: nil)
                
                if (!self.loggedIn){
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let tabVC = storyboard.instantiateViewControllerWithIdentifier("tabVC") as! UITabBarController
                    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                    appDelegate.window?.rootViewController = tabVC
                    self.loggedIn = true
                }
                })
        }
        return false
    
                    }

    
}

