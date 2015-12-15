//
//  FirstViewController.swift
//  SoundFuze
//
//  Created by Dylan Fiedler on 10/23/15.
//  Copyright © 2015 xor. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import CoreData
import PKHUD

class Track {
    var uri = NSURL()
    var position = Int()
    var upVotes = Int()
}

class FirstViewController: UIViewController, SPTAudioStreamingPlaybackDelegate, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {
    
    var window: UIWindow?
    
    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var trackTable: UITableView!
    
    let kClientID = "db5f7f0e54ed4342b9de8cc08ddcc29b"
    let kCallbackURL = "soundfuze://"
        //localhost for ios Simulator
    
//    let kTokenSwapURL = "http://localhost:1234/swap"
//    let kTokenRefreshURL = "http://localhost:1234/refresh"
    
    let kTokenSwapURL = "http://Dylans-MacBook-Pro.local:1234/swap"
    let kTokenRefreshURL = "http://Dylans-MacBook-Pro.local:1234/refresh"
    
    var player: SPTAudioStreamingController?
    let auth = SPTAuth.defaultInstance()
    var session: SPTSession?
    
    var queuedTracks: [SPTPartialTrack] = []
    var selected: TrackTableViewCell!
    var selectedIndex: NSIndexPath?
    var position: NSTimeInterval?
    var next = 0
    var sortedCount = 1
    var uris: [Track] = []
    var savedURIs = [NSManagedObject]()
    var currentPlaybackPosition: NSTimeInterval?
    var host = false
    var fuzer = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.trackTable.delegate = self
        self.trackTable.dataSource = self
        self.trackTable.alpha = 0.0
        self.trackTable.remembersLastFocusedIndexPath = true
        
        loadTableTimer = NSTimer.scheduledTimerWithTimeInterval(0.0, target: self, selector: "showTable", userInfo: nil, repeats: false)
        let longPress = UILongPressGestureRecognizer(target: self, action: "longPressGestureRecognized:")
        longPress.delegate = self
        longPress.minimumPressDuration = 1.0
        self.trackTable.addGestureRecognizer(longPress)
        
        let shortPress = UITapGestureRecognizer(target: self, action: "shortPressGestureRecognized:")
        shortPress.delegate = self
        self.trackTable.addGestureRecognizer(shortPress)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "add:", name: "addToQueue", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "addOthers:", name: "addOthersToQueue", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "saveQueue", name: "saveQueue", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "load:", name: "loadPlaylist", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playPause", name: "playPause", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playNext", name: "playNext", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playPrevious", name: "playPrevious", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reset", name: "reset", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "clearQueue", name: "clearQueue", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "isHosting", name: "isHosting", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "isFuzing", name: "isFuzing", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "receivedUpVote:", name: "receivedUpVote", object: nil)
        
        // Do any additional setup after loading the view
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if let sessionObj : AnyObject = NSUserDefaults.standardUserDefaults().objectForKey("SpotifySession") {
            
            let sessionDataObj : NSData = sessionObj as! NSData
            self.session = NSKeyedUnarchiver.unarchiveObjectWithData(sessionDataObj) as! SPTSession
            
            if !self.session!.isValid() {

                
                SPTAuth.defaultInstance().renewSession(self.session,  callback: { (error : NSError!, newsession : SPTSession!) -> Void in
                    
                    if error == nil {
                        
                        let sessionData = NSKeyedArchiver.archivedDataWithRootObject(self.session!)
                        userDefaults.setObject(sessionData, forKey: "SpotifySession")
                        userDefaults.synchronize()
                        self.session = newsession
                    } else {
                        print("error refreshing new spotify session")
                    }
                })
                
            } else {
                print("session valid")
                
            }
        }
        
    }
    
    var loadTableTimer = NSTimer()
    override func viewWillAppear(animated: Bool) {
        
        PKHUD.sharedHUD.contentView = PKHUDSystemActivityIndicatorView()
        PKHUD.sharedHUD.show()
        loadRecent()
    }
    
    func showTable(){
        UIView.animateWithDuration(1.0, animations: ({
            self.trackTable.alpha = 1.0
        }))
        self.trackTable.hidden = false
        PKHUD.sharedHUD.hide(afterDelay: 1.0)
    }
    
    override func viewDidDisappear(animated: Bool) {
        self.trackTable.alpha = 0.0
        saveRecent()
    }
    
    func load(notification: NSNotification){
        loadStoredPlaylist()
        saveRecent()
    }
    
    
    func loadStoredPlaylist(){
        //1
        let appDelegate =
        UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext
        
        //2
        let fetchRequest = NSFetchRequest(entityName: "Load")
        let sortDescriptor = NSSortDescriptor(key: "position", ascending: true)
        
        fetchRequest.sortDescriptors = [sortDescriptor]

        //3
        do {
            print("fetching...")
            let results =
            try managedContext.executeFetchRequest(fetchRequest)
            
            if (!results.isEmpty){
                savedURIs = results as! [NSManagedObject]
                loadTracks(session)
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        
        saveRecent()
    }
    
    func loadRecent(){
        //1
        
        self.uris.removeAll(keepCapacity: true)
        self.savedURIs.removeAll()
        
        let appDelegate =
        UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext
        
        //2
        let fetchRequest = NSFetchRequest(entityName: "Recent")
        let sortDescriptor = NSSortDescriptor(key: "position", ascending: false)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        //3
        do {
            
            print("fetching...")
            let results =
            try managedContext.executeFetchRequest(fetchRequest)
            
            if (!results.isEmpty){
                for item in results {
                    savedURIs.append(item as! NSManagedObject)
                }
                loadTracks(session)
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
    

    func loadTracks(session: SPTSession!){
    print("loading tracks...")
        
    for trackURI in savedURIs {
        
        let uri = trackURI.valueForKey("uri") as! String
        SPTRequest.requestItemAtURI(NSURL(string: uri), withSession: session, callback: {(error: NSError!, trackObj: AnyObject?) -> Void in
            if (error != nil){
                print("track lookup got error: \(error)")
                return
            }
            
            let track = trackObj as! SPTTrack
            let add = Track ()
            add.uri = (track.uri)
            if (trackURI.valueForKey("position") != nil){
                add.position = trackURI.valueForKey("position") as! Int
            } else {
                add.position = self.uris.count
            }
            add.upVotes = trackURI.valueForKey("upvotes") as! Int
                
            
            self.uris.append(add)
            dispatch_async(dispatch_get_main_queue()) {
                self.uris.sortInPlace({ $1.position > $0.position })
            }
            
            if (self.uris.count == self.savedURIs.count){
            dispatch_async(dispatch_get_main_queue()) {
               // self.trackTable.alpha = 1.0
                self.trackTable.reloadData()
                //self.trackTable.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Fade)
                
            }
            }
        })
        
    }
        self.trackTable.hidden = false
        self.player?.queueURIs(self.uris, clearQueue: true, callback: nil)
        showTable()
    }
    
    func playUsingSession(session: SPTSession!, trackIndex: Int){
        
        if (player == nil){
            player = SPTAudioStreamingController(clientId: kClientID)
        }

        player?.loginWithSession(session, callback: {(error: NSError!) -> Void in
            if error != nil {
                print("Playback error: \(error.description)")
                return
            }
        })
        
        var queue: [NSURL] = []
        for track in uris {
            queue.append(track.uri)
        }
        
        self.player?.queueURIs(queue, clearQueue: true, callback: nil)
        self.player?.playURIs(queue, fromIndex: Int32(trackIndex), callback: nil)
        queue.removeAll(keepCapacity: false)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return uris.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("track", forIndexPath: indexPath) as! TrackTableViewCell
        if (indexPath.row < self.uris.count){
           
            let trackURI = self.uris[indexPath.row].uri
            
            SPTRequest.requestItemAtURI(trackURI, withSession: session, callback: {(error: NSError!, trackObj: AnyObject?) -> Void in
                if (error != nil){
                    print("track lookup got error: \(error)")
                    return
                }

                let track = trackObj as! SPTTrack
                let albumImage = track.album.covers.first as! SPTImage
                let image = albumImage.imageURL.description
                let imageData = NSData(contentsOfURL: NSURL(string: image)!)
            
                if imageData != nil {
                    cell.albumArtwork.image = UIImage(data: imageData!)
                }
                cell.trackName.text = track.name
                let artistInfo = track.artists.first!.name
                cell.artist.text = artistInfo
            })
        }
        
        if (fuzer){
            cell.upVote.alpha = 0.3
            cell.upVote.enabled = true
            cell.upVoteLabel.hidden = true
        } else if (host){
            cell.upVote.alpha = 0.0
            cell.upVote.enabled = false
            cell.upVoteLabel.hidden = false
            if (indexPath.row < self.uris.count){
                let upvotes = self.uris[indexPath.row].upVotes
                cell.upVoteLabel.text = "\(upvotes) upvotes"
            }
        } else {
            cell.upVote.alpha = 0.0
            cell.upVote.enabled = false
            cell.upVoteLabel.hidden = true
        }
        
        return cell
        
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! TrackTableViewCell
        
        if (!fuzer){
    
        if (selected != nil){
        for (var i = 0; i < self.uris.count; i++){
            let indexPath = NSIndexPath(forRow: i, inSection: 0)
            if self.trackTable.cellForRowAtIndexPath(indexPath) != nil {
            let clear = self.trackTable.cellForRowAtIndexPath(indexPath) as! TrackTableViewCell
            UIView.animateWithDuration(0.5, animations: {(
                clear.backgroundColor = UIColor.clearColor()
            )}, completion: nil)
            }
        }
        }
        
        if ((selected == nil || cell != selected)){
        
            cell.backgroundColor = UIColor.lightGrayColor()
            
            let userDefaults = NSUserDefaults.standardUserDefaults()
            
            if let sessionObj : AnyObject = NSUserDefaults.standardUserDefaults().objectForKey("SpotifySession") {
                
                
                //pull session data from login
                let sessionDataObj : NSData = sessionObj as! NSData
                let session = NSKeyedUnarchiver.unarchiveObjectWithData(sessionDataObj) as! SPTSession
                
                //if this stored session is no longer valid, renew and store new session for same key
                if !session.isValid() {
                    // withServiceEndpointAtURL: NSURL(string: kTokenRefreshURL),
                    SPTAuth.defaultInstance().renewSession(session, callback: { (error : NSError!, newsession : SPTSession!) -> Void in
                        
                        if error == nil {
                            
                            let sessionData = NSKeyedArchiver.archivedDataWithRootObject(session)
                            userDefaults.setObject(sessionData, forKey: "SpotifySession")
                            userDefaults.synchronize()
                            
                            if (newsession != nil){
                                self.session = newsession
                            //now play music using this new session and update global session variabl
                                self.playUsingSession(newsession, trackIndex: indexPath.row)
                                
                            } else {
                                self.playUsingSession(session, trackIndex: indexPath.row)
                            }
                        } else {
                            print("error refreshing new spotify session")
                        }
                    })
                } else {
                    //otherwise, no need to refresh old session, play song
                    
                    playUsingSession(session, trackIndex: indexPath.row)
                }
            }
            selected = cell
            selectedIndex = indexPath
            NSNotificationCenter.defaultCenter().postNotificationName("makePause", object: nil)
        } else {
            player?.stop({(error: NSError!) -> Void in
                if (error != nil){
                    print("Cannot stop playback: \(error)")
                }
            })
            NSUserDefaults.standardUserDefaults().setObject(nil, forKey: "indexPathRow")
            NSUserDefaults.standardUserDefaults().synchronize()
            NSNotificationCenter.defaultCenter().postNotificationName("makePlay", object: nil)
            selected = nil
            cell.backgroundColor = UIColor.clearColor()
        }
 
        self.trackTable.deselectRowAtIndexPath(indexPath, animated: false)
        } else {
            
            //upvote and downvote songs
            let trackIdentifier = self.uris[indexPath.row].uri.description 
            
            if (cell.upVote.alpha != 1.0){
            cell.upVote.alpha = 1.0
            self.uris[indexPath.row].upVotes += 1
                print("upvoted , current vote count: \(self.uris[indexPath.row].upVotes)")
                NSNotificationCenter.defaultCenter().postNotificationName("sendUpVote", object: trackIdentifier)
                //UPVOTE A SONG
            } else {
                //DOWNVOTE A SONG
                cell.upVote.alpha = 0.3
                self.uris[indexPath.row].upVotes += 1
                NSNotificationCenter.defaultCenter().postNotificationName("sendDownVote", object: nil)
            }
        }
        
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if (!fuzer){
            return true
        } else {
            return false
        }
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if (!fuzer){
        if motion == .MotionShake {
            let alertController = UIAlertController(title: "Clear queue?", message: "Would you like to clear the current queue?", preferredStyle: .Alert)
            let clearAction = UIAlertAction(title: "Clear", style: .Default, handler: {(action: UIAlertAction!) -> Void in
            self.clearQueue()
        })
            let cancelAction = UIAlertAction(title:"Cancel", style: .Default, handler:nil)
            alertController.addAction(cancelAction)
            alertController.addAction(clearAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
        }
    }
    
    
    //allows user to swipe to delete a specifc cell from queue and updates accordingly
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (host || (!host && !fuzer)){
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            self.uris.removeAtIndex(indexPath.row)
            saveRecent()
            self.trackTable.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
        }
        
    }

    
    func add(notification: NSNotification){
       let userInfo: Dictionary <String,AnyObject!> = notification.userInfo as! Dictionary<String,
        AnyObject!>
        
        let newTrack = userInfo["track"] as! SPTTrack
        let trackURI = newTrack.uri as NSURL
        
            //add to end of queue
            let add = Track()
            add.uri = trackURI
            add.position = self.uris.count
            add.upVotes = 0
        
        let index = self.uris.indexOf(({$0.uri == add.uri}))
        
        if index == nil {
            self.uris.append(add)
        }
        
       
        dispatch_async(dispatch_get_main_queue()) {
            self.uris.sortInPlace({ $1.position > $0.position })
            self.trackTable.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Fade)
        }
        
        saveRecent()
    }
    
    func addOthers(notification: NSNotification){
        let userInfo: Dictionary <String,AnyObject!> = notification.userInfo as! Dictionary<String,
            AnyObject!>
        
        let newTrackString = userInfo["track"] as! String
       let trackURI = NSURL(string: newTrackString)
        
        if trackURI  != nil {
       
        let add = Track()
        add.uri = trackURI!
        add.position = self.uris.count
        add.upVotes = 0
            
        print(add.position)

        let index = self.uris.indexOf(({$0.uri == add.uri}))
        
        if index == nil  {
            self.uris.append(add)
            }
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            self.uris.sortInPlace({ $1.position > $0.position })
            self.trackTable.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Fade)
        }
        saveRecent()
    }
    
    func saveRecent(){
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        let fetchRequest = NSFetchRequest(entityName: "Recent")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            do {
                
                try managedContext.executeRequest(deleteRequest)
                
            } catch let error as NSError {
                // TODO: handle the error
                print("ERROR ERROR ERROR ON DELETE: \(error)")
            }
        
        //2
        let entity =  NSEntityDescription.entityForName("Recent", inManagedObjectContext:managedContext)
        for trackURI in self.uris {
            let indexOf = self.uris.indexOf(({$0.uri == trackURI.uri.description}))
            print(indexOf)
            let song = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
            song.setValue(trackURI.uri.description, forKey: "uri")
            song.setValue(trackURI.position, forKey: "position")
            song.setValue(trackURI.upVotes, forKey: "upvotes")
        }
        
        
        do {
            try managedContext.save()
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
    }

    //save current queue as a playlist in CoreData
    func saveQueue() {
        
        let alertController = UIAlertController(title: "Playlist name", message: "What would you like the name of your playlist to be?", preferredStyle: .Alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Default, handler: {(action: UIAlertAction!) in
            self.dismissViewControllerAnimated(true, completion: nil)
        })
        
        let defaultAction = UIAlertAction(title: "Save", style: .Default, handler:{ (action: UIAlertAction!) in
            
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext
            
            //2
            let entity =  NSEntityDescription.entityForName("SongURIs", inManagedObjectContext:managedContext)
            let text = alertController.textFields![0].text as String!
            for trackURI in self.uris {
                let song = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
                song.setValue(trackURI.uri.description, forKey: "uri")
                song.setValue(text, forKey: "name")
                song.setValue(trackURI.position, forKey: "position")
            }
            
            do {
                try managedContext.save()
            } catch let error as NSError  {
                print("Could not save \(error), \(error.userInfo)")
            }
            
        })
        
        alertController.addAction(cancelAction)
        alertController.addAction(defaultAction)
        
        alertController.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
            textField.placeholder = "Name"
        })
    
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func playPause(){
    }
    
    func playNext(){
        player?.skipNext(nil)
        if (selectedIndex != nil && selectedIndex!.row + 1 < self.uris.count){
            self.trackTable.deselectRowAtIndexPath(selectedIndex!, animated: true)
            self.trackTable.selectRowAtIndexPath(NSIndexPath(forRow: selectedIndex!.row + 1, inSection: (selectedIndex?.section)!), animated: true, scrollPosition: .None)
            self.tableView(trackTable, didSelectRowAtIndexPath: NSIndexPath(forRow: selectedIndex!.row + 1, inSection: (selectedIndex?.section)!))
        } else {
            player?.stop(nil)
        }
        
    }
    
    func playPrevious(){
        player?.skipPrevious(nil)
        self.trackTable.deselectRowAtIndexPath(selectedIndex!, animated: true)
        self.trackTable.selectRowAtIndexPath(NSIndexPath(forRow: selectedIndex!.row - 1, inSection: (selectedIndex?.section)!), animated: true, scrollPosition: .None)
        self.tableView(trackTable, didSelectRowAtIndexPath: NSIndexPath(forRow: selectedIndex!.row - 1, inSection: (selectedIndex?.section)!))
    }
    
    func longPressGestureRecognized(gestureRecognizer: UIGestureRecognizer) {
        self.trackTable.editing = true
        
    }
    
    func shortPressGestureRecognized(gestureRecognizer: UIGestureRecognizer) {
        if (self.trackTable.editing == true){
            self.trackTable.editing = false
        }
        self.trackTable.resignFirstResponder()
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        
        if (gestureRecognizer.isKindOfClass(UITapGestureRecognizer)){
            if self.trackTable.editing == true {
                return true
            } else {
                return false
            }
        }
        return true
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.None
    }
    
   func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
            // remove the dragged row's model
            let other = self.uris.removeAtIndex(sourceIndexPath.row)
            // insert it into the new position
            self.uris.insert(other, atIndex: destinationIndexPath.row)
            saveRecent()
            player?.queueURIs(self.uris, clearQueue: true, callback: nil)
    }
    
    
    
    func removePreviousRecentPlaylists(){
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext
        
        //2
        let fetchRequest = NSFetchRequest(entityName: "Recent")
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            do {
                
                try managedContext.executeRequest(deleteRequest)

            } catch let error as NSError {
                // TODO: handle the error
                print("error deleting: \(error)")
            }
        
        
    }
    
    func receivedUpVote(notification: NSNotification!){
        var trackIdentifier = notification.object as! String
        trackIdentifier = trackIdentifier.stringByReplacingOccurrencesOfString(" ", withString: "")
        for track in uris {
            if (track.uri.description == trackIdentifier){
                track.upVotes = track.upVotes + 1
                print("upvote receieved and displayed")
                break;
            }
        }
        let indexSet = NSIndexSet(index: 0)
        dispatch_async(dispatch_get_main_queue()) {
            self.uris.sortInPlace({ $1.position > $0.position })
            self.trackTable.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Fade)
        }
        //self.trackTable.reloadData()
        saveRecent()
        self.player?.queueURIs(self.uris, clearQueue: true, callback: nil)
    }
    
    func clearQueue(){
        self.uris.removeAll()
        self.trackTable.reloadData()
        removePreviousRecentPlaylists()
        if (player != nil){
            player?.stop(nil)
        }
    }
    
    func isHosting(){
        host = true
        fuzer = false
        self.trackTable.reloadData()
    }
    
    func isFuzing(){
        fuzer = true
        host = false
        clearQueue()
        self.trackTable.reloadData()
    }
    
    func reset(){
        host = false
        fuzer = false
    }
}

