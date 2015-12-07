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
    
    
    @IBOutlet weak var hostButton: UIButton!
    @IBOutlet weak var peersTable: UITableView!
    @IBOutlet weak var connectionStatus: UILabel!
    
    var songService =  SongServiceManager()
    
    var peerNames: [String] = []
    var queue: [NSURL?] = []
    var notification: NSNotification? = nil
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        songService.delegate = self
        peersTable.delegate = self
        peersTable.dataSource = self
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "add:", name: "addToQueue", object: nil)
        
        if let connectionsObj : AnyObject = NSUserDefaults.standardUserDefaults().objectForKey("connectedDevices"){
            print("connected devices \(connectionsObj)")
            
        }
    }
    
    override func viewWillAppear(animated: Bool) {
//        if let connectionsObj : [AnyObject] = NSUserDefaults.standardUserDefaults().objectForKey("connectedDevices"){
//            print("connected devices \(connectionsObj)")
//            
////            for items in connectionsObj {
////                self.peerNames.append(items.description)
////            }
//            //let connections = connectionsObj as! String
//            var parse: [AnyObject?]
//        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func refresh(sender: AnyObject) {
        self.connectionStatus.text = "Refreshing..."
    }
    
    
    var timer = NSTimer()
    var host = false
    
    @IBAction func hostNetwork(sender: AnyObject) {
        
        if (!host){
            
        
            let alertController = UIAlertController(title: "Host or Fuze?", message: "Would you like to host a playlist, or fuze with another?", preferredStyle: .Alert)
            let hostAction = UIAlertAction(title: "Host", style: .Default, handler: {(action: UIAlertAction!) in
                self.connectionStatus.text = "Currently Hosting..."
            })
            
            let connectAction = UIAlertAction(title: "Fuze", style: .Default, handler: {(action: UIAlertAction!) in
                self.connectionStatus.text = "Fuzing with others"
                })
            
            alertController.addAction(hostAction)
            alertController.addAction(connectAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)

            timer = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: Selector("fadeInOut"), userInfo: nil, repeats: true)
            
            songService.start()
            
            self.hostButton.enabled = true
            host = true
            
        } else {
            self.connectionStatus.text = "Tap to Fuze"
            timer.invalidate()
            songService.stop()
            host = false
            self.hostButton.enabled = true
        }
    }
    
    func fadeInOut(){
        UIView.animateWithDuration(2.0, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            if (self.hostButton.alpha == 1.0){
                self.hostButton.alpha = 0.0
            } else {
                self.hostButton.alpha = 1.0
            }
            }, completion: nil)
        self.hostButton.enabled = true
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
                self.peerNames = connectedDevices
                print("Connected to \(connectedDevices)")
            } else {
                self.peerNames = []
            }
        }
        
        userDefaults.setObject(connectedDevices, forKey: "connectedDevices")
        userDefaults.synchronize()
        self.peersTable.reloadData()
    }

    func add(notification: NSNotification){
        let userInfo: Dictionary <String,AnyObject!> = notification.userInfo as! Dictionary<String, AnyObject!>
        let newTrack = userInfo["track"]
        songService.updateQueue(newTrack!.uri!.description)
        let user = userInfo["user"] as! String
    
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

