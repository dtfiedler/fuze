//
//  TrackTableViewController.swift
//  SoundFuze
//
//  Created by Dylan Fiedler on 11/27/15.
//  Copyright © 2015 xor. All rights reserved.
//

import UIKit

class TrackTableViewController: UITableViewController {
    
    var session: SPTSession?
    var trackURIs = [NSManagedObject]()
    var tracks: [SPTPartialTrack] = []
    var playlist: String?
    
    @IBOutlet var trackTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "pushToQueue")
        
        if let sessionObj : AnyObject = NSUserDefaults.standardUserDefaults().objectForKey("SpotifySession") {
            
            let sessionDataObj : NSData = sessionObj as! NSData
            self.session = NSKeyedUnarchiver.unarchiveObjectWithData(sessionDataObj) as! SPTSession
            
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if !self.session!.isValid() {
            
            SPTAuth.defaultInstance().renewSession(session,  callback: { (error : NSError!, newsession : SPTSession!) -> Void in
                
                if error == nil {
                    
                    let sessionData = NSKeyedArchiver.archivedDataWithRootObject(self.session!)
                    userDefaults.setObject(sessionData, forKey: "SpotifySession")
                    userDefaults.synchronize()
                    self.session = newsession
                } else {
                    print("error refreshing new spotify session")
                }
            })
            
        }
            
            loadPlaylist()
        }
        
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadPlaylist() {
        //1
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext
        
        //2
        let fetchRequest = NSFetchRequest(entityName: "SongURIs")
        
        //3
        do {
            print("fetching...")
            let results = try managedContext.executeFetchRequest(fetchRequest)
            trackURIs = results as! [NSManagedObject]
            loadTracks(session, playlist: playlist)
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
    
    func loadTracks(session: SPTSession!, playlist: String!){
        print("loading tracks...")
        
        //self.trackURIs.removeAll()
        
        for trackURI in trackURIs {
            
            if ((trackURI.valueForKey("name") as! String).lowercaseString == playlist.lowercaseString){
                SPTRequest.requestItemAtURI(NSURL(string: trackURI.valueForKey("uri") as! String), withSession: session, callback: {(error: NSError!, trackObj: AnyObject?) -> Void in
                    if (error != nil){
                        print("track lookup got error: \(error)")
                        return
                    }
                    
                    let track = trackObj as! SPTTrack
                    self.tracks.append(track as SPTPartialTrack)
                    self.trackTable.reloadData()
                })
            }
        }
        
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tracks.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("track", forIndexPath: indexPath)
        cell.textLabel?.text = tracks[indexPath.row].name
        return cell
    }
    
    func pushToQueue(){
        let alertController = UIAlertController(title: "Load Playlist?", message: "Would you like to load this playlist to your current queue?", preferredStyle: .Alert)
        
        let defaultAction = UIAlertAction(title: "Load", style: .Default, handler:{ (action: UIAlertAction!) in
            
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext
            
            //2
            let entity =  NSEntityDescription.entityForName("Load", inManagedObjectContext:managedContext)
            
            //need to delete all previous values in Load entity
            self.removePreviousLoadedPlaylists()
            
            for trackURI in self.tracks {
                var song = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
                song.setValue(trackURI.uri.description, forKey: "uri")
            }
            
            do {
                try managedContext.save()
            } catch let error as NSError  {
                print("Could not save \(error), \(error.userInfo)")
            }

            
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main",bundle: nil)
            var destViewController : UIViewController
            destViewController = mainStoryboard.instantiateViewControllerWithIdentifier("navController")
            self.presentViewController(destViewController, animated: true, completion: {() in
                NSNotificationCenter.defaultCenter().postNotificationName("loadPlaylist", object: nil)
            })
            
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Default, handler: {(action: UIAlertAction!) in
                self.dismissViewControllerAnimated(true, completion: nil)
            })
        
        alertController.addAction(defaultAction)
        alertController.addAction(cancelAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
        
        print("send to queue")
        
        
    }
    
    func removePreviousLoadedPlaylists(){
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext
        
        //2
        let fetchRequest = NSFetchRequest(entityName: "Load")
        if #available(iOS 9.0, *) {
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            do {
                
                try managedContext.executeRequest(deleteRequest)
                //try myPersistentStoreCoordinator.executeRequest(deleteRequest, withContext: myContext)
                    
                   // managedContext.executeRequest(deleteRequest, withContext: managedContext)
            } catch let error as NSError {
                // TODO: handle the error
            }

        } else {
            // Fallback on earlier versions
        }
        
        
    }
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
}