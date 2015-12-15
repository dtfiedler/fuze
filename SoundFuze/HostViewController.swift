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
    func upvotingSong(manger: SongServiceManager, trackIdentifier: String)
    
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "sendCurrentQueue", name: "sendCurrentQueue", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "sendUpVote:", name: "sendUpVote", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "sendDownVote:", name: "sendDownVote", object: nil)
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
    var hosting = false
    var host = false
    var fuzer = false
    var currentQueue: [String?] = []
    
    @IBAction func hostNetwork(sender: AnyObject) {
        if (!hosting){
            songService.start()
            let alertController = UIAlertController(title: "Host or Fuze?", message: "Would you like to host a playlist, or fuze with another?", preferredStyle: .Alert)
            let hostAction = UIAlertAction(title: "Host", style: .Default, handler: {(action: UIAlertAction!) in
                self.connectionStatus.text = "Currently Hosting..."
                self.host = true
                //push current queue to connected devices
               self.sendCurrentQueue()
                
                self.songService.start()
                NSNotificationCenter.defaultCenter().postNotificationName("isHosting", object: nil)
            })
            
            let connectAction = UIAlertAction(title: "Fuze", style: .Default, handler: {(action: UIAlertAction!) in
                self.connectionStatus.text = "Fuzing with others"
                self.fuzer = true
                
                self.songService.stop()
                
                NSNotificationCenter.defaultCenter().postNotificationName("isFuzing", object: nil)
               
            })
            
            let cancel = UIAlertAction(title: "Cancel", style: .Default, handler: nil)
            
            
            alertController.addAction(hostAction)
            alertController.addAction(connectAction)
            alertController.addAction(cancel)
            self.presentViewController(alertController, animated: true, completion: nil)

            timer = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: Selector("fadeInOut"), userInfo: nil, repeats: true)
            
            
            
            self.hostButton.enabled = true
            hosting = true
            
            
        } else {
            self.connectionStatus.text = "Tap to Fuze"
            timer.invalidate()
            songService.stop()
            hosting = false
            self.hostButton.enabled = true
            NSNotificationCenter.defaultCenter().postNotificationName("reset", object: nil)
        }
    }
    
    func sendCurrentQueue(){
        
               let appDelegate =
        UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext
        
        //2
        let fetchRequest = NSFetchRequest(entityName: "Recent")
        let sortDescriptor = NSSortDescriptor(key: "position", ascending: false)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        //3
        do {
            let results = try managedContext.executeFetchRequest(fetchRequest)
            
            if (!results.isEmpty){
                for item in results {
                    self.currentQueue.append(item.uri.description as! String)
                }
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        
        self.currentQueue = self.currentQueue.reverse()
        self.songService.updateNonHostQueue(self.currentQueue)
    }
    
    func fadeInOut(){
        UIView.animateWithDuration(1.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            if (self.hostButton.alpha == 1.0){
                self.hostButton.alpha = 0.0
            } else {
                self.hostButton.alpha = 1.0
            }
            }, completion: nil)
        self.hostButton.enabled = true
    }
    
    func sendUpVote(notification: NSNotification){
        let trackIdentifer = notification.object as! String
        songService.upVoteSong(trackIdentifer)
        print("sent an upvote for \(trackIdentifer)")
    }
    
    func sendDownVote(notification: NSNotification){
        let trackIdentifer = notification.object as! String
        //songService.upVoteSong(trackIdentifer)
        print("send a downvote for\(trackIdentifer)")
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
            if (!connectedDevices.isEmpty){
                self.peerNames = connectedDevices
                print("Connected to \(connectedDevices)")
                if (host){
                    self.sendCurrentQueue()
                }
            } else {
                self.peerNames = []
        }
        
        userDefaults.setObject(connectedDevices, forKey: "connectedDevices")
        userDefaults.synchronize()
        self.peersTable.reloadData()
    }

    func add(notification: NSNotification){
        let userInfo: Dictionary <String,AnyObject!> = notification.userInfo as! Dictionary<String, AnyObject!>
        let newTrack = userInfo["track"]
        let user = userInfo["user"] as! String
        
        if (fuzer){
            songService.updateQueue(newTrack!.uri!.description)
        }
    
    }
    
    func addToQueue(manager: SongServiceManager, track: String) {
        NSNotificationCenter.defaultCenter().postNotificationName("addOthersToQueue", object: nil, userInfo: ["track": track])
    }
    
    func upvotingSong(manager: SongServiceManager, trackIdentifier: String){
        NSNotificationCenter.defaultCenter().postNotificationName("receivedUpVote", object: trackIdentifier)
        print("recevied upvote from a fuzer")
    }
    
    func refreshConnection(manager: SongServiceManager){
        NSLog("refreshing connection")
        self.peersTable.reloadData()
    }
    
    @IBAction func showMenu(sender: AnyObject) {
        NSNotificationCenter.defaultCenter().postNotificationName("toggleMenu", object: nil)
    }
}

