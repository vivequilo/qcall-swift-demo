//
//  MediaConnection.swift
//  qcall
//
//  Created by Augusto Alonso on 8/7/20.
//  Copyright © 2020 Augusto Alonso. All rights reserved.
//

import Foundation
import WebRTC

public class MediaConnection: BaseConnection, RTCPeerConnectionDelegate {

    
    var roomDelegate: RoomDelegate
    var remoteStream: QMediaStream?
    init(roomDelegate : RoomDelegate, connectionVerb: ConnectionVerb, signalingClient: SignalingClient, client: Client, localClient: Client, resolutionConstraints: QVideoResolutionConstraint) {
        self.roomDelegate = roomDelegate
        super.init(connectionType: .media, connectionVerb: connectionVerb, signalingClient: signalingClient, client: client, localClient: localClient, resolutionConstraints: resolutionConstraints)
    }
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
                //TODO Add more handlers
        print("New state ", stateChanged.rawValue)
    }
    public func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        let remoteStream = QMediaStream(stream: stream)
        self.remoteStream = remoteStream
        self.roomDelegate.roomEvent(client: client, onStreamAdded: remoteStream)
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        self.remoteStream = nil
        self.roomDelegate.roomEvent(onStreamRemoved: self.client.id)
    }
    
    public func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        //Handle negopublic tiation TODO
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        self.addIcecandidate(iceCandidate: candidate)
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        //Removed the ice candidate will have to see whpublic y this is triggered
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        
    }
}

