//
//  FirstViewController.swift
//  SoundFuze
//
//  Created by Dylan Fiedler on 10/23/15.
//  Copyright © 2015 xor. All rights reserved.
//

import UIKit
import AVFoundation
import CoreData

class FirstViewController: UIViewController, SPTAudioStreamingPlaybackDelegate, UITableViewDataSource, UITableViewDelegate {
    
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
    var position: NSTimeInterval?
    var next = 0
    var uris: [NSURL] = []
    var savedURIs = [NSManagedObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.trackTable.delegate = self
        self.trackTable.dataSource = self
        //self.loadPlaylist()
       // NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateAfterFirstlogin", name: "loginSuccesfull", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "add:", name: "addToQueue", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "addOthers:", name: "addOthersToQueue", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loadPlaylist:", name: "loadPlaylist", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "saveQueue", name: "saveQueue", object: nil)
        
        // Do any additional setup after loading the view
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if let sessionObj : AnyObject = NSUserDefaults.standardUserDefaults().objectForKey("SpotifySession") {
            
            let sessionDataObj : NSData = sessionObj as! NSData
            let session = NSKeyedUnarchiver.unarchiveObjectWithData(sessionDataObj) as! SPTSession
            
            if !session.isValid() {
                
                //withServiceEndpointAtURL: NSURL(string: kTokenRefreshURL),
                
                SPTAuth.defaultInstance().renewSession(session,  callback: { (error : NSError!, newsession : SPTSession!) -> Void in
                    
                    if error == nil {
                        
                        let sessionData = NSKeyedArchiver.archivedDataWithRootObject(session)
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
    
//    func load(){
//        self.loadPlaylist()
//    }
    
    func loadPlaylist(notification: NSNotification) {
        let userInfo: Dictionary <String,AnyObject!> = notification.userInfo as! Dictionary<String,
            AnyObject!>
        let playlist = userInfo["playlist"] as! String
        
        //1
        let appDelegate =
        UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext
        
        //2
        let fetchRequest = NSFetchRequest(entityName: "SongURIs")
        
        //3
        do {
            print("fetching...")
            let results =
            try managedContext.executeFetchRequest(fetchRequest)
            savedURIs = results as! [NSManagedObject]
            loadTracks(session!, playlist: playlist)
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
    
    func loadTracks(session: SPTSession!, playlist: String){

        
        for trackURI in savedURIs {
    
        if ((trackURI.valueForKey("name") as! NSString).lowercaseString == playlist.lowercaseString){
        SPTRequest.requestItemAtURI(NSURL(string: trackURI.valueForKey("uri") as! String), withSession: session, callback: {(error: NSError!, trackObj: AnyObject?) -> Void in
            if (error != nil){
                print("track lookup got error: \(error)")
                return
            }
            
            let track = trackObj as! SPTTrack
            self.queuedTracks.append(track as! SPTPartialTrack)
            self.uris.append(track.uri)
            self.trackTable.reloadData()
           })
           self.player?.queueURIs(self.uris, clearQueue: true, callback: nil)
        }
        }
    }
    
    @IBAction func clearQueue(sender: AnyObject) {
        self.uris.removeAll()
        self.queuedTracks.removeAll()
        self.trackTable.reloadData()
    }
    
    @IBAction func mostRecentQueue(sender: AnyObject) {
//        self.loadPlaylist()
//        self.loadTracks(session)
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
        
        self.player?.playURIs(uris, fromIndex: Int32(trackIndex), callback: nil)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return uris.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("track", forIndexPath: indexPath) as! TrackTableViewCell
        if (indexPath.row < queuedTracks.count){
        cell.trackName.text = queuedTracks[indexPath.row].name
        let artistInfo = queuedTracks[indexPath.row].artists.first!.name
        cell.artist.text = artistInfo
            
        let trackURI = queuedTracks[indexPath.row].playableUri
        
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
            })
        }
        
        return cell
        
    }
    
    var timer:  NSTimer!
    func updateProgress(){
        let cell: TrackTableViewCell! = timer.userInfo!["cell"] as! TrackTableViewCell
        let currentProgress = self.player?.currentPlaybackPosition
        let duration = self.player?.currentTrackDuration
        let min = floor(currentProgress!);
        let current = min/duration!
        cell.progress.setProgress(Float(current), animated: true)
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        for (var i = 0; i < queuedTracks.count; i++){
            let indexPath = NSIndexPath(forRow: i, inSection: 0)
            self.trackTable.cellForRowAtIndexPath(indexPath)?.backgroundColor = UIColor.clearColor()
        }
        
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! TrackTableViewCell
        
        if (selected == nil || cell != selected){
        
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
                    self.next = indexPath.row + 1
                    self.trackTable.reloadData()
                }
            }
            selected = cell
            timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("updateProgress"), userInfo: ["cell": cell], repeats: true)
        } else {
            player?.stop({(error: NSError!) -> Void in
                if (error != nil){
                    print("Cannot stop playback: \(error)")
                }
            })
            timer.invalidate()
            selected = nil
            cell.backgroundColor = UIColor.clearColor()
            self.trackTable.reloadData()
        }
 
        self.trackTable.deselectRowAtIndexPath(indexPath, animated: false)
        
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    
    //allows user to swipe to delete a specifc cell from queue and updates accordingly
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            self.queuedTracks.removeAtIndex(indexPath.row)
            self.uris.removeAtIndex(indexPath.row)
            self.trackTable.reloadData()
        }
    }

    //
    func add(notification: NSNotification){
       let userInfo: Dictionary <String,AnyObject!> = notification.userInfo as! Dictionary<String,
        AnyObject!>
        
        let newTrack = userInfo["track"] as! SPTTrack
        let trackURI = newTrack.uri as NSURL
        
        
        if (uris.contains(trackURI)){
            //don't add same tracks twice without asking
            NSLog("Track already in queue")
            //notify user and ask if they still want to add?
            
        } else {
            //add to end of queue
            self.uris.append(trackURI)
            self.queuedTracks.append(newTrack as SPTPartialTrack)
        }
        
        self.trackTable.reloadData()
    }
    
    func addOthers(notification: NSNotification){
        let userInfo: Dictionary <String,AnyObject!> = notification.userInfo as! Dictionary<String,
            AnyObject!>
        
        let newTrackString = userInfo["track"] as! String
        var trackURI: NSURL?
        var newTrack: SPTPartialTrack?
        
            trackURI = NSURL(string: newTrackString)
            
        SPTRequest.requestItemAtURI(trackURI, withSession: self.session, callback: {(error: NSError?, trackObj: AnyObject?)-> Void in
            if (error != nil){
                print("error: \(error)")
                return
            }
            newTrack = trackObj as! SPTPartialTrack
            self.queuedTracks.append(newTrack! as SPTPartialTrack)
            self.trackTable.reloadData()
        })

        
        if (uris.contains(trackURI!)){
            NSLog("Track already in queue")
        } else {
            //add to end of queue
            self.uris.append(trackURI!)
        }
        
        self.trackTable.reloadData()
        
    }
    
    func request(trackURI: NSURL!)-> SPTPartialTrack{
        var newTrack: SPTPartialTrack!
        SPTRequest.requestItemAtURI(trackURI, withSession: self.session, callback: {(error: NSError?, trackObj: AnyObject?)-> Void in
            if (error != nil){
                print("error: \(error)")
                return
            }
             newTrack = trackObj as! SPTPartialTrack
        })
        
        return newTrack
        
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    //save current queue as a playlist in CoreData
    func saveQueue() {
        
        
        let alertController = UIAlertController(title: "Playlist name", message: "What would you like the name of your playlist to be?", preferredStyle: .Alert)
        
        let defaultAction = UIAlertAction(title: "Save", style: .Default, handler:{ (action: UIAlertAction!) in
            
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext
            
            //2
            let entity =  NSEntityDescription.entityForName("SongURIs", inManagedObjectContext:managedContext)
            let song = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
    
            for trackURI in self.uris {
                song.setValue(trackURI.description, forKey: "uri")
            }
            
            let text = alertController.textFields![0].text as String!
            
            song.setValue(text, forKey: "name")
            
            do {
                try managedContext.save()
            } catch let error as NSError  {
                print("Could not save \(error), \(error.userInfo)")
            }
            
        })
        
        alertController.addAction(defaultAction)
        
        alertController.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
            textField.placeholder = "Name"
        })
    
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    @IBAction func next(sender: AnyObject) {
         player?.skipNext(nil)
    }
    
    func playNext(sender:AnyObject){
        player?.skipNext(nil)
    }
    
    @IBAction func showMenu(sender: AnyObject) {
        NSNotificationCenter.defaultCenter().postNotificationName("toggleMenu", object: nil)
    }
    
    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didChangeToTrack trackMetadata: [NSObject : AnyObject]!) {
        let uri = trackMetadata[SPTAudioStreamingMetadataTrackURI] as! NSURL
        for i in 0...uris.count {
            if uri == uris[i]{
                let indexPath = NSIndexPath(forRow: i, inSection: 0)
                trackTable.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: UITableViewScrollPosition.Middle)
            }
            
            
        }
        
    }
    
}

