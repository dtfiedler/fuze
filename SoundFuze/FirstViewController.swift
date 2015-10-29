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
    let kTokenSwapURL = "http://localhost:1234/swap"
    let kTokenRefreshURL = "http://localhost:1234/refresh"
    
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

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateAfterFirstlogin", name: "SpotifyLoginSuccesfull", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "add:", name: "addToQueue", object: nil)
        
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
//                        self.fetch()
//                        self.loadTracks(newsession)
                    } else {
                        print("error refreshing new spotify session")
                    }
                })
                
            } else {
                print("session valid")

            }
    }
    }
    
    func fetch() {
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
            print(savedURIs.count)
            
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }

    
    func loadTracks(session: SPTSession!){
        for trackURI in savedURIs {
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
    
    @IBAction func clearQueue(sender: AnyObject) {
        self.uris.removeAll()
        self.queuedTracks.removeAll()
        self.trackTable.reloadData()
    }
    
    @IBAction func mostRecentQueue(sender: AnyObject) {
        self.fetch()
        self.loadTracks(session)
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
        print("play")
        self.player?.playURIs(uris, fromIndex: Int32(trackIndex), callback: nil)
        if (trackIndex < uris.count - 1){
            next += 1
        }
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
        //cell.progress.hidden = true
        
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
                cell.albumArtwork.image = UIImage(data: imageData!)
            })
        }
        
        return cell
        
    }
    
    var timer:  NSTimer!
    func updateProgress(){
        var i: Float = 0.0
        print("updating")
        var cell: TrackTableViewCell! = timer.userInfo!["cell"] as! TrackTableViewCell
        //let time = ((player!.currentPlaybackPosition)/(player!.currentTrackDuration))
        cell.progress.progress = i + 0.05
        let reload = timer.userInfo!["indexPath"] as! NSIndexPath
        print(reload)
        //if (reload){
            self.trackTable.reloadRowsAtIndexPaths([reload], withRowAnimation: UITableViewRowAnimation.None)
        //}
        //cell.progress.progress = time
        //cell.progress.progress = player?.currentPlaybackPosition as! Float
        
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        for (var i = 0; i < queuedTracks.count; i++){
            let indexPath = NSIndexPath(forRow: i, inSection: 0)
            self.trackTable.cellForRowAtIndexPath(indexPath)?.backgroundColor = UIColor.clearColor()
        }
        
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! TrackTableViewCell
        
        cell.progress.hidden = false
        ///timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "updateProgress", userInfo:  ["cell": cell, "indexPath": indexPath], repeats: true)
        
        if (selected == nil || cell != selected){
        
            cell.backgroundColor = UIColor.lightGrayColor()
            
            let userDefaults = NSUserDefaults.standardUserDefaults()
            
            if let sessionObj : AnyObject = NSUserDefaults.standardUserDefaults().objectForKey("SpotifySession") {
                
                let sessionDataObj : NSData = sessionObj as! NSData
                let session = NSKeyedUnarchiver.unarchiveObjectWithData(sessionDataObj) as! SPTSession
                
                if !session.isValid() {
                    // withServiceEndpointAtURL: NSURL(string: kTokenRefreshURL),
                    SPTAuth.defaultInstance().renewSession(session, callback: { (error : NSError!, newsession : SPTSession!) -> Void in
                        
                        if error == nil {
                            
                            let sessionData = NSKeyedArchiver.archivedDataWithRootObject(session)
                            userDefaults.setObject(sessionData, forKey: "SpotifySession")
                            userDefaults.synchronize()
                            
                            self.session = newsession
                            self.playUsingSession(self.session, trackIndex: indexPath.row)
                            
                        } else {
                            print("error refreshing new spotify session")
                        }
                    })
                } else {
                    print("session valid")
                    playUsingSession(session, trackIndex: indexPath.row)
                    self.next = indexPath.row + 1
                    self.trackTable.reloadData()
                }
            }
            selected = cell
        } else {
            
            player?.stop({(error: NSError!) -> Void in
                if (error != nil){
                    print("Cannot stop playback: \(error)")
                }
            })
            selected = nil
            cell.backgroundColor = UIColor.clearColor()
            self.trackTable.reloadData()
        }
 
        self.trackTable.deselectRowAtIndexPath(indexPath, animated: false)
        
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            self.queuedTracks.removeAtIndex(indexPath.row)
            self.uris.removeAtIndex(indexPath.row)
            self.trackTable.reloadData()
        }
    }

    func add(notification: NSNotification){
       let userInfo: Dictionary <String,AnyObject!> = notification.userInfo as! Dictionary<String,
        AnyObject!>
        let newTrack = userInfo["track"]
        NSLog("Adding \(newTrack) to queue")
        let trackURI = newTrack!.uri as! NSURL
        
        if (uris.contains(trackURI)){
            NSLog("Track already in queue")
            //alert
            
        } else {
            self.uris.append(trackURI)
            self.queuedTracks.append(newTrack as! SPTPartialTrack)
            print(uris)
            
        }
        
        self.trackTable.reloadData()
        
    }

    @IBAction func saveQueue(sender: AnyObject) {
        //1
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext
        
        //2
        let entity =  NSEntityDescription.entityForName("SongURIs",
            inManagedObjectContext:managedContext)
        
        for trackURI in uris {
            let song = NSManagedObject(entity: entity!,
            insertIntoManagedObjectContext: managedContext)
            song.setValue(trackURI.description, forKey: "uri")
        }

        do {
            try managedContext.save()
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
        
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
    
    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didStopPlayingTrack trackUri: NSURL!) {
        print("next track")
        let indexPath = NSIndexPath(forRow: next, inSection: 0)
        self.trackTable.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: UITableViewScrollPosition.Middle)
        playUsingSession(self.session!, trackIndex: next)
    }
    
}

