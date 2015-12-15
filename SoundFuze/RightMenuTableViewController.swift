//
//  RightMenuTableViewController.swift
//  SoundFuze
//
//  Created by Dylan Fiedler on 12/8/15.
//  Copyright © 2015 xor. All rights reserved.
//

import UIKit

class RightMenuTableViewController: UITableViewController {
    var selectedMenuItem : Int = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Customize apperance of table view
        tableView.contentInset = UIEdgeInsetsMake(64.0, 0, 0, 0) //
        tableView.separatorStyle = .None
        tableView.backgroundColor = UIColor.clearColor()
        tableView.scrollsToTop = false
        
        // Preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = true
        
        //tableView.selectRowAtIndexPath(NSIndexPath(forRow: selectedMenuItem, inSection: 0), animated: false, scrollPosition: .Middle)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        return 7
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCellWithIdentifier("CELL")
        
        if (cell == nil) {
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "CELL")
            cell!.backgroundColor = UIColor.clearColor()
            cell!.textLabel?.textColor = UIColor.darkGrayColor()
            let selectedBackgroundView = UIView(frame: CGRectMake(0, 0, cell!.frame.size.width, cell!.frame.size.height))
            selectedBackgroundView.backgroundColor = UIColor.grayColor().colorWithAlphaComponent(0.2)
            cell!.selectedBackgroundView = selectedBackgroundView
        }
        
        var text: String?
        
        let image = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        
        cell?.addSubview(image)
        
        switch (indexPath.row) {
        case 0: text = "Previous"
        
            break
        case 1: text = "Play"
            break
        case 2: text = "Next"
            break
        case 3: text = "Shuffle"
            image.image = UIImage(named: "shuffle.png")
            break
        case 4: text = "Repeat"
            image.image = UIImage(named: "repeat.png")
            break
        case 5: text = "Save"
            break
        case 6: text = "Clear"
            break
        default: text = ""
            break
        }
        
        cell!.textLabel?.text = text
        
        return cell!
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50.0
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        print("did select row: \(indexPath.row)")
        
        selectedMenuItem = indexPath.row
        
        //Present new view controller
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main",bundle: nil)
        var destViewController : UIViewController
        switch (indexPath.row) {
        case 0:
            NSNotificationCenter.defaultCenter().postNotificationName("playPrevious", object: nil)
            break
        case 1:
            NSNotificationCenter.defaultCenter().postNotificationName("playPause", object: nil)
//            destViewController = mainStoryboard.instantiateViewControllerWithIdentifier("playlists") as! PlaylistTableViewController
            break
        case 2:
            NSNotificationCenter.defaultCenter().postNotificationName("playNext", object: nil)
//            destViewController = mainStoryboard.instantiateViewControllerWithIdentifier("peers")
            break
        case 3:
            NSNotificationCenter.defaultCenter().postNotificationName("shuffle", object: nil)
//            destViewController = mainStoryboard.instantiateViewControllerWithIdentifier("settings")
            break
        case 4:
            NSNotificationCenter.defaultCenter().postNotificationName("Repeat", object: nil)
//            destViewController = mainStoryboard.instantiateViewControllerWithIdentifier("LoginVC")
            
//            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
//            appDelegate.window?.rootViewController = destViewController
            break
        case 5:
            NSNotificationCenter.defaultCenter().postNotificationName("saveQueue", object: nil)
            break;
        case 6:
            NSNotificationCenter.defaultCenter().postNotificationName("clearQueue", object: nil)
        default:
            
//            destViewController = mainStoryboard.instantiateViewControllerWithIdentifier("tabVC")
            break
        }
        //sideMenuController()?.setContentViewController(destViewController)
        self.tableView.deselectRowAtIndexPath(indexPath, animated: false)
        sideMenuController()?.rightMenu?.hideSideMenu()
        
    }
    
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    }
    */
    
}

