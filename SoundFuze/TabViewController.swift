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
        
        playPrevious = UIBarButtonItem(barButtonSystemItem: .Rewind , target: self, action: "playPrevious:")
        playNext = UIBarButtonItem(barButtonSystemItem: .FastForward, target: self, action: "playNext:")
        playPause = UIBarButtonItem(barButtonSystemItem: .Play, target: self, action: "playPause:")
        
        self.navigationController?.navigationItem.setRightBarButtonItems([playPrevious!, playPause!, playNext!], animated: false)
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
    
    @IBAction func playPause(sender: AnyObject) {
        if (!play){
            NSNotificationCenter.defaultCenter().postNotificationName("play", object: nil)
            let playButton = UIBarButtonItem(barButtonSystemItem: .Play, target: self, action: "playPause:") as UIBarButtonItem
            self.navigationController?.navigationItem.setRightBarButtonItems([self.playPrevious!, playButton, self.playNext!], animated: true)
            play = true
        } else {
            NSNotificationCenter.defaultCenter().postNotificationName("pause", object: nil)
            let pause = UIBarButtonItem(barButtonSystemItem: .Pause, target: self, action: "playPause:") as UIBarButtonItem
            self.navigationController?.navigationItem.setRightBarButtonItems([self.playPrevious!, pause, self.playNext!], animated: true)
            
            play = false
        }
    }
    
    @IBAction func playPrevious(sender: AnyObject) {
        NSNotificationCenter.defaultCenter().postNotificationName("playPrevious", object: nil)
    }
    
    @IBAction func playNext(sender: AnyObject) {
        NSNotificationCenter.defaultCenter().postNotificationName("playNext", object: nil)
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
