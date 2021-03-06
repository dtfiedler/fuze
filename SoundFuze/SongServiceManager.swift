//
//  Multipeer.swift
//  SoundFuze
//
//  Created by Dylan Fiedler on 10/27/15.
//  Copyright © 2015 xor. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class SongServiceManager : NSObject {
    
    // Service type must be a unique string, at most 15 characters long
    // and can contain only ASCII lowercase letters, numbers and hyphens.
    private let SongServiceType = "myplaylist"
    private let myPeerId = MCPeerID(displayName: UIDevice.currentDevice().name)
    private let serviceAdvertiser : MCNearbyServiceAdvertiser
    private let serviceBrowser : MCNearbyServiceBrowser
    private var upVote = false
    
    var delegate : SongServiceManagerDelegate?
    
    lazy var session : MCSession = {
        let session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.Required)
        session.delegate = self
        return session
    }()
    
    override init() {
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: SongServiceType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: SongServiceType)
        super.init()
        self.serviceAdvertiser.delegate = self
        self.serviceBrowser.delegate = self
  
    }
    
    func start(){
        self.serviceAdvertiser.startAdvertisingPeer()
        self.serviceBrowser.startBrowsingForPeers()
    }
    
    func stop (){
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }
    
    deinit {
        //self.serviceAdvertiser.stopAdvertisingPeer()
        //self.serviceBrowser.stopBrowsingForPeers()
    }
    
    func updateQueue(track : String) {
        NSLog("%@", "update queue: \(track)")
        if session.connectedPeers.count > 0 {
                print("sending update")
            do { try self.session.sendData(track.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, toPeers: self.session.connectedPeers, withMode: MCSessionSendDataMode.Reliable)
                    print("sent song successfully")
            } catch {
            print("\(error)")
        }
        }
    }
    
    func updateNonHostQueue(queue: [String?]){
        if session.connectedPeers.count > 0 {
            print("sending current queue of \(queue.count) tracks to non hosts")
            for track in queue {
                if session.connectedPeers.count > 0 {
                    print(track!)
                    do { try self.session.sendData(track!.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, toPeers: self.session.connectedPeers, withMode: MCSessionSendDataMode.Reliable)
                        print("sent song successfully")
                    } catch {
                        print("\(error)")
                    }
                }
            }
        }
    }
    
    func upVoteSong(var trackIdentifier: String?){
        if(session.connectedPeers.count > 0){
            upVote = true
            trackIdentifier = trackIdentifier! + " UPVOTE"
        do {
            try self.session.sendData(trackIdentifier!.dataUsingEncoding(NSUTF8StringEncoding)!, toPeers: self.session.connectedPeers, withMode: MCSessionSendDataMode.Reliable)
            
            print("upvoted \(trackIdentifier!)")
        } catch {
            print("upvote failed...")
        }
        }
    }
}

extension SongServiceManager : MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: NSError) {
        NSLog("%@", "didNotStartAdvertisingPeer: \(error)")
    }
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: NSData?, invitationHandler: (Bool,MCSession) -> Void){
        NSLog("%@", "didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, self.session)
        
    }
    
}

extension SongServiceManager : MCNearbyServiceBrowserDelegate {
    
    func browser(browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError) {
        NSLog("%@", "didNotStartBrowsingForPeers: \(error)")
    }
    
    func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?){
        NSLog("%a", "found peer: \(peerID)")
        NSLog("%@", "invitePeer: \(peerID)")
        self.delegate?.connectedDevicesChanged(self, connectedDevices: session.connectedPeers.map({$0.displayName}))
        browser.invitePeer(peerID, toSession: self.session, withContext: nil, timeout: 30)
    }
    
    func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        NSLog("%@", "lostPeer: \(peerID)")
    }
    
}

extension MCSessionState {
    
    func stringValue() -> String {
        switch(self) {
        case .NotConnected: return "NotConnected"
        case .Connecting: return "Connecting"
        case .Connected: return "Connected"
        default: return "Unknown"
        }
    }
    
}

extension SongServiceManager : MCSessionDelegate {
    
    func session(session: MCSession!, peer peerID: MCPeerID!, didChangeState state: MCSessionState) {
        NSLog("%@", "peer \(peerID) didChangeState: \(state.stringValue())")
        self.delegate?.connectedDevicesChanged(self, connectedDevices: session.connectedPeers.map({$0.displayName}))
        if state == .NotConnected{
            print("disconnected from host, must reconnect")
        }
    }
    
    func session(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!) {
        NSLog("%@", "didReceiveData: \(data)")
        let str: NSString? = NSString(data: data!, encoding: NSUTF8StringEncoding)
        var string: String? = str as String!
        if ((((str?.containsString("UPVOTE").boolValue))) == false){
            self.delegate!.addToQueue(self, track: string!)
        } else {
            string = string?.stringByReplacingOccurrencesOfString("UPVOTE", withString: "")
            self.delegate!.upvotingSong(self, trackIdentifier: string!)
            upVote = false
        }
    }
    
    func session(session: MCSession!, didReceiveStream stream: NSInputStream!, withName streamName: String!, fromPeer peerID: MCPeerID!) {
        NSLog("%@", "didReceiveStream")
    }
    
    func session(session: MCSession!, didFinishReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, atURL localURL: NSURL!, withError error: NSError!) {
        NSLog("%@", "didFinishReceivingResourceWithName")
    }
    
    func session(session: MCSession!, didStartReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, withProgress progress: NSProgress!) {
        NSLog("%@", "didStartReceivingResourceWithName")
    }

    
}

