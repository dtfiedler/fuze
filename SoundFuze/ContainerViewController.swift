//
//  ContainerViewController.swift
//  SoundFuze
//
//  Created by Dylan Fiedler on 10/28/15.
//  Copyright © 2015 xor. All rights reserved.
//

import UIKit

class ContainerViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var menuContainer: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layer.shadowOpacity = 0.8
        self.view.layer.shadowColor = UIColor.grayColor().CGColor
        // Initially close menu programmatically.  This needs to be done on the main thread initially in order to work.
        dispatch_async(dispatch_get_main_queue()) {
            self.closeMenu(false)
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "toggleMenu", name: "toggleMenu", object: nil)
        
        // Close the menu when the device rotates
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "rotated", name: UIDeviceOrientationDidChangeNotification, object: nil)
        
    }
    
    // Cleanup notifications added in viewDidLoad
    
    
    func toggleMenu(){
        scrollView.contentOffset.x == 0  ? closeMenu() : openMenu()
    }
    
    func closeMenu(animated:Bool = true){
        scrollView.setContentOffset(CGPoint(x: 250, y: 0), animated: animated)
    }
    
    func openMenu(){
        print("opening menu")
        scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
    }
    
    func rotated(){
        if UIDeviceOrientationIsLandscape(UIDevice.currentDevice().orientation) {
            dispatch_async(dispatch_get_main_queue()) {
                print("closing menu on rotate")
                self.closeMenu()
            }
        }
    }
    
}

extension ContainerViewController : UIScrollViewDelegate {
    func scrollViewDidScroll(scrollView: UIScrollView) {
        print("scrollView.contentOffset.x:: \(scrollView.contentOffset.x)")
    }
    
    // http://www.4byte.cn/question/49110/uiscrollview-change-contentoffset-when-change-frame.html
    // When paging is enabled on a Scroll View,
    // a private method _adjustContentOffsetIfNecessary gets called,
    // presumably when present whatever controller is called.
    // The idea is to disable paging.
    // But we rely on paging to snap the slideout menu in place
    // (if you're relying on the built-in pan gesture).
    // So the approach is to keep paging disabled.
    // But enable it at the last minute during scrollViewWillBeginDragging.
    // And then turn it off once the scroll view stops moving.
    //
    // Approaches that don't work:
    // 1. automaticallyAdjustsScrollViewInsets -- don't bother
    // 2. overriding _adjustContentOffsetIfNecessary -- messing with private methods is a bad idea
    // 3. disable paging altogether.  works, but at the loss of a feature
    // 4. nest the scrollview inside UIView, so UIKit doesn't mess with it.  may have worked before,
    //    but not anymore.
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
         if UIDeviceOrientationIsLandscape(UIDevice.currentDevice().orientation){
            scrollView.pagingEnabled = false
        } else {
            scrollView.pagingEnabled = true
        }
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        scrollView.pagingEnabled = false
    }
}