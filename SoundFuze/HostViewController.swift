//
//  HostViewController.swift
//  SoundFuze
//
//  Created by Dylan Fiedler on 10/27/15.
//  Copyright © 2015 xor. All rights reserved.
//

import UIKit
import Foundation
import MultipeerConnectivity

protocol SongServiceManagerDelegate {
    
    func connectedDevicesChanged(manager : SongServiceManager, connectedDevices: [String])
    func addToQueue(manager : SongServiceManager, track: String)
    
}

class HostViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    @IBOutlet weak var peersTable: UITableView!
    @IBOutlet weak var connectionStatus: UILabel!
    
    var songService =  SongServiceManager()
    
    var peerNames: [String] = []
    var queue: [NSURL?] = []
    var notification: NSNotification? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        songService.delegate = self
        peersTable.delegate = self
        peersTable.dataSource = self
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "add:", name: "addToQueue", object: nil)
        //NSNotificationCenter.defaultCenter().postNotificationName("closeMenu", object: nil)
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().postNotificationName("closeMenu", object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func refresh(sender: AnyObject) {
        self.connectionStatus.text = "Refreshing..."
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peerNames.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        print("table refreshed")
        let cell = tableView.dequeueReusableCellWithIdentifier("peerID", forIndexPath: indexPath) as UITableViewCell
        if (!peerNames.isEmpty && indexPath.row < peerNames.count){

            cell.textLabel!.text = peerNames[indexPath.row]
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)! as UITableViewCell
        NSLog("added phone to playlist")
        
        if ((cell.accessoryView == nil) && cell.textLabel!.text != ""){
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        } else {
            cell.accessoryType = UITableViewCellAccessoryType.None
        }
        
        self.peersTable.reloadData()
    }
    
}




extension HostViewController : SongServiceManagerDelegate {
    
    func connectedDevicesChanged(manager: SongServiceManager, connectedDevices: [String]) {
        NSOperationQueue.mainQueue().addOperationWithBlock {
            if (!connectedDevices.isEmpty){
                self.connectionStatus.text = "Select the users you would like to fuze with!"
                self.peerNames = connectedDevices
                print("Connected to \(connectedDevices)")
                self.peersTable.reloadData()
            } else {
                self.connectionStatus.text = "No fuzers found..."
                self.peerNames = []

            }
        }
        
        self.peersTable.reloadData()
    }

    func add(notification: NSNotification){
        let userInfo: Dictionary <String,AnyObject!> = notification.userInfo as! Dictionary<String, AnyObject!>
        let newTrack = userInfo["track"]
        songService.updateQueue(newTrack!.uri!.description)
        let user = userInfo["user"] as! String
        if (user != UIDevice.currentDevice().name){
            var alertview = UIAlertView()
            alertview.title = "Queue updated by..."
            alertview.message = "The queue has been updated"
            alertview.delegate = self
            alertview.addButtonWithTitle("Okay")
            alertview.show()
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    
    }
    
    func addToQueue(manager: SongServiceManager, track: String) {
            NSNotificationCenter.defaultCenter().postNotificationName("addOthersToQueue", object: nil, userInfo: ["track": track])
            let alertController = UIAlertController(title: "Track added", message: "A track has been added by another user", preferredStyle: .Alert)
        
        
    }
    
    func refreshConnection(manager: SongServiceManager){
        NSLog("refreshing connection")
        self.peersTable.reloadData()
    }
    
    @IBAction func showMenu(sender: AnyObject) {
        NSNotificationCenter.defaultCenter().postNotificationName("toggleMenu", object: nil)
    }
}

