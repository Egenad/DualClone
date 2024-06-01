//
//  PTPAdvertiser.swift
//  DualClone
//
//  Created by Angel Terol on 25/5/24.
//

import Foundation
import MultipeerConnectivity

class PTPAdvertiser: NSObject, MCNearbyServiceAdvertiserDelegate{
    
    var mcAdvertiser: MCNearbyServiceAdvertiser?
    var mcSession: MCSession!
    
    func startAdvertising(_ peerID: MCPeerID, _ session: MCSession){
        mcAdvertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: "dual-clone")
        mcAdvertiser!.delegate = self
        mcAdvertiser!.startAdvertisingPeer()
        mcSession = session
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("Received invitation from \(peerID.displayName)")
        invitationHandler(true, mcSession)
    }
    
    func disconnect(){
        mcAdvertiser?.stopAdvertisingPeer()
    }
}
