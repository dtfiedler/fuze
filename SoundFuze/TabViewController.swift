//
//  TabViewController.swift
//  SoundFuze
//
//  Created by Dylan Fiedler on 10/28/15.
//  Copyright © 2015 xor. All rights reserved.
//

import UIKit

class TabViewController: UITabBarController, ENSideMenuDelegate {
    
    var play = false
    
    var playPrevious: UIBarButtonItem?
    var playNext: UIBarButtonItem?
    var playPause: UIBarButtonItem?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sideMenuController()?.sideMenu?.delegate = self
        self.sideMenuController()?.rightMenu?.delegate = self
        
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: "makePause", name: "makePause", object: nil)
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: "makePlay", name: "makePlay", object:nil)
        
//        playPrevious = UIBarButtonItem(barButtonSystemItem: .Rewind , target: self, action: "playPrevious:")
//        playNext = UIBarButtonItem(barButtonSystemItem: .FastForward, target: self, action: "playNext:")
//        playPause = UIBarButtonItem(barButtonSystemItem: .Play, target: self, action: nil)
//        
        //self.navigationItem.rightBarButtonItems = [playNext!, playPause!, playPrevious!]
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func toggleSideMenu(sender: AnyObject) {
        toggleSideMenuView()
    }
    
    @IBAction func saveQueue(sender: AnyObject) {
        NSNotificationCenter.defaultCenter().postNotificationName("saveQueue", object: nil)
    }
    
    @IBAction func toggleRightSideMenu(sender: AnyObject){
        toggleRightMenuView()
    }
    
    // MARK: - ENSideMenu Delegate
    func sideMenuWillOpen() {
        print("sideMenuWillOpen")
    }
    
    func sideMenuWillClose() {
        print("sideMenuWillClose")
    }
    
    func sideMenuShouldOpenSideMenu() -> Bool {
        print("sideMenuShouldOpenSideMenu")
        return true
    }
    
    func sideMenuDidClose() {
        print("sideMenuDidClose")
    }
    
    func sideMenuDidOpen() {
        print("sideMenuDidOpen")
    }

}
