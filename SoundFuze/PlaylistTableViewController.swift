//
//  PlaylistTableViewController.swift
//  SoundFuze
//
//  Created by Dylan Fiedler on 11/25/15.
//  Copyright © 2015 xor. All rights reserved.
//

import UIKit

class PlaylistTableViewController: UITableViewController, ENSideMenuDelegate {
    
    var playlists = [NSManagedObject]()
    var allPlaylists: [String] = []
    var playlist: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sideMenuController()?.sideMenu?.delegate = self
        self.navigationController?.navigationBarHidden = false
        let menuButton: UIBarButtonItem = UIBarButtonItem(image: UIImage(named: "dot"), style: UIBarButtonItemStyle.Bordered, target: self, action: "toggleSideMenu")
        
       // UIBarButtonItem(image: <#T##UIImage?#>, style: <#T##UIBarButtonItemStyle#>, target: <#T##AnyObject?#>, action: <#T##Selector#>)
        
        self.navigationItem.setLeftBarButtonItem(menuButton, animated: false);
        self.navigationItem.title = "Playlists"
        
        fetch()
        self.tableView.reloadData()
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
            let results = try managedContext.executeFetchRequest(fetchRequest)
            playlists = results as! [NSManagedObject]
                for lists in playlists {
                if ((lists.valueForKey("name") as? NSString)!.lowercaseString != "nil") && !self.allPlaylists.contains(lists.valueForKey("name") as! String){
                    self.allPlaylists.append(lists.valueForKey("name") as! String)
                }
            }
            self.tableView.reloadData()
            
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return allPlaylists.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("playlist", forIndexPath: indexPath)
        if indexPath.row < allPlaylists.count {
            cell.textLabel?.text = allPlaylists[indexPath.row]
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        playlist = allPlaylists[indexPath.row]
        //NSNotificationCenter.defaultCenter().postNotificationName("loadPlaylist", object: nil, userInfo: ["playlist": playlist])
        //let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main",bundle: nil)
        //let destViewController = mainStoryboard.instantiateViewControllerWithIdentifier("tabVC")
        self.performSegueWithIdentifier("showTracks", sender: self)
        
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            let appDelegate =
            UIApplication.sharedApplication().delegate as! AppDelegate
            
            let managedContext = appDelegate.managedObjectContext
            
            //2
            let fetchRequest = NSFetchRequest(entityName: "SongURIs")
            
            //3
            do {
                managedContext.deleteObject(playlists[indexPath.row] as NSManagedObject)
                allPlaylists.removeAtIndex(indexPath.row)
                try managedContext.save()
                
                //tableView.reloadData()
                // remove the deleted item from the `UITableView`
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                
            } catch let error as NSError {
                print("Could not fetch \(error), \(error.userInfo)")
            }

        }
    }
    
    func toggleSideMenu() {
        toggleSideMenuView()
    }
    
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

    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    
    // Override to support editing the table view.
//    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
//        if editingStyle == .Delete {
//            // Delete the row from the data source
//            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
//        } else if editingStyle == .Insert {
//            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
//        }    
//    }
    

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        var destination = segue.destinationViewController as! TrackTableViewController
        destination.playlist = playlist
    }
    

}
