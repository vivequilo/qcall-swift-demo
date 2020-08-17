//
//  RTCClient.swift
//  qcall
//
//  Created by Augusto Alonso on 8/6/20.
//  Copyright © 2020 Augusto Alonso. All rights reserved.
//

import Foundation
import WebRTC

class RTCClient {
    
    private let localClient: Client
    private let roomDelegate: RoomDelegate
    
    private let dataConnectionDelegate: DataConnectionDelegate?
    private let videoResolutionconstraint: QVideoResolutionConstraint
    private let peerConnectionFactory: PeerConnectionFactory
    private var mediaConnections: [String: MediaConnection] = [:]
    private var dataConnections: [String: DataConnection] = [:]
    private var mediaConnectionIcePool: [String: [RTCIceCandidate]] = [:]
    private var dataConnectionIcePool: [String: [RTCIceCandidate]] = [:]
    private var peerId: String {
        get { return localClient.id }
    }
    let signalingClient: SignalingClient
    var localStream: QMediaStream?
    var cameraPosition: CameraPosition = .front
    
    var iceServers: [RTCIceServer] = [
    RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"], username: "", credential: "")
    ]
    
    
    
    init(
        localClient : Client,
        signalingDelegate: SignalingClientDelegate,
        dataConnectionDelegate: DataConnectionDelegate?,
        videoResolutionconstraint: QVideoResolutionConstraint,
        roomDelegate: RoomDelegate
    ) {
        self.localClient = localClient
        self.signalingClient = SignalingClient.init(peerId: localClient.id)
        self.signalingClient.delegate = signalingDelegate
        self.dataConnectionDelegate = dataConnectionDelegate
        self.videoResolutionconstraint = videoResolutionconstraint
        self.roomDelegate = roomDelegate
        self.peerConnectionFactory = PeerConnectionFactory(videoResolutionConstraints: videoResolutionconstraint)
    }
    
    func connect(callers: [Client]) -> [Client] {
        if localStream == nil {
            startLocalVideoCapture()
        }
        var mutableCallers = callers
        var i = 0
        mutableCallers.forEach {
            caller in
            self.initPeerConnection(client: caller, verb: .oferrer, type: .media)
            self.initPeerConnection(client: caller, verb: .oferrer, type: .data)
            self.mediaConnections[caller.id]?.call()
            self.dataConnections[caller.id]?.call()
            mutableCallers[i].call = self.mediaConnections[caller.id]
            mutableCallers[i].conn = self.dataConnections[caller.id]
            i += 1
        }
        return mutableCallers
    }
    
    func close(){
        signalingClient.close()
    }
    
    func switchCamera(){
        if let localStream  = self.localStream{
//            self.cameraPosition.toggle()
            
            let videoTrack = QVideoTrack.init(track: self.peerConnectionFactory.createLocalVideoTrack(position: self.cameraPosition))
            for localVideoTrack in localStream.videoTracks{
                let renderer = localVideoTrack.renderer
                renderer?.removeCurrentTrack()
                renderer?.track = videoTrack
                self.localStream?.removeVideoTrack(track: localVideoTrack)
            }
            mediaConnections.forEach {
                id, conn in
                conn.peerConnection?.senders.forEach {
                    sender in
                    if sender.track?.kind == videoTrack.kind {
                        sender.track = videoTrack.track
                    }
                }
            }
            self.localStream?.addVideoTrack(track: videoTrack)
        }
    }
    
    func addIceCandidateToMediaConnection(client: Client, iceCandidate: RTCIceCandidate, type: ConnectionType){
        switch type {
        case .media:
            if mediaConnections.keys.contains(client.id){
                mediaConnections[client.id]?.addIcecandidate(iceCandidate: iceCandidate)
            }else{
                if !mediaConnectionIcePool.keys.contains(client.id) {
                    mediaConnectionIcePool[client.id] = []
                }
                mediaConnectionIcePool[client.id]?.append(iceCandidate)
            }
        case .data:
            if dataConnections.keys.contains(client.id){
                dataConnections[client.id]?.addIcecandidate(iceCandidate: iceCandidate)
            }else{
                if !dataConnectionIcePool.keys.contains(client.id){
                    dataConnectionIcePool[client.id] = []
                }
                dataConnectionIcePool[client.id]?.append(iceCandidate)
            }
        }
    }
    
    func onRemoteSessionReceived(client: Client, sdp: RTCSessionDescription, verb: ConnectionVerb, connectionType: ConnectionType, connectionId: String? = nil){
        if !mediaConnections.keys.contains(client.id) || !dataConnections.keys.contains(client.id){
         initPeerConnection(client: client, verb: verb, type: connectionType)
        }else{
            mediaConnections[client.id]?.connectionVerb = verb
            dataConnections[client.id]?.connectionVerb = verb
        }
        switch connectionType {
        case .media:
            mediaConnections[client.id]?.setRemoteDescription(sdp: sdp, connectionId: connectionId)
        case .data:
            dataConnections[client.id]?.setRemoteDescription(sdp: sdp, connectionId: connectionId)
        }
    }
    
    func startLocalVideoCapture(){
        if localStream == nil {
            self.localStream = self.peerConnectionFactory.createLocalMediaStream()
            if let localStream = self.localStream{
                self.roomDelegate.roomEvent(localPeerId : self.peerId, onLocalStream: localStream)
            }
        }
    }
    
    func startLocalVideoCapture(videoRenderer: QVideoRenderer){
        if localStream == nil {
            self.localStream = self.peerConnectionFactory.createLocalMediaStream()
            if let localStream = self.localStream{
                videoRenderer.track = QVideoTrack(track: localStream.mStream.videoTracks[0])
                self.roomDelegate.roomEvent(localPeerId : self.peerId, onLocalStream: localStream)
            }
        }
    }
    
    fileprivate func initPeerConnection(client: Client, verb: ConnectionVerb, type: ConnectionType){
        switch type {
        case .media:
            let mediaConnection = MediaConnection(roomDelegate: roomDelegate, connectionVerb: verb, signalingClient: signalingClient, client: client, localClient: localClient, resolutionConstraints: videoResolutionconstraint)
            mediaConnection.peerConnection = self.peerConnectionFactory.createPeerConnection(type, iceServers: iceServers, delegate: mediaConnection)
            mediaConnections[client.id] = mediaConnection
            mediaConnectionIcePool[client.id]?.forEach{
                iceCandidate in
                mediaConnections[client.id]?.addIcecandidate(iceCandidate: iceCandidate)
            }
            if let localStream = self.localStream {
                mediaConnections[client.id]?.addStream(stream: localStream)
            }
        case .data:
            let dataConnection = DataConnection.init(roomDelegate: roomDelegate, connectionVerb: verb, signalingClient: signalingClient, client: client, localClient: localClient, resolutionConstraints: videoResolutionconstraint)
            dataConnection.peerConnection = self.peerConnectionFactory.createPeerConnection(type, iceServers: iceServers, delegate: dataConnection)
            dataConnections[client.id] = dataConnection
            dataConnectionIcePool[client.id]?.forEach{
                iceCandidate in
                dataConnections[client.id]?.addIcecandidate(iceCandidate: iceCandidate)
            }
        }
        
    }
}

