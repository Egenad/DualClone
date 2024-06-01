//
//  PTPBrowser.swift
//  DualClone
//
//  Created by Angel Terol on 25/5/24.
//

import Foundation
import MultipeerConnectivity

class PTPBrowser: NSObject, MCNearbyServiceBrowserDelegate {
    
    var mcBrowser: MCNearbyServiceBrowser?
    var mcSession: MCSession!
    
    func startBrowse(_ peerID: MCPeerID, _ session: MCSession){
        mcBrowser = MCNearbyServiceBrowser(peer: peerID, serviceType: "dual-clone")
        mcBrowser!.delegate = self
        mcBrowser!.startBrowsingForPeers()
        mcSession = session
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("Found peer: \(peerID.displayName)")
        mcBrowser!.invitePeer(peerID, to: mcSession, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Lost peer: \(peerID.displayName)")
    }
    
    func disconnect(){
        mcBrowser?.stopBrowsingForPeers()
    }
}
