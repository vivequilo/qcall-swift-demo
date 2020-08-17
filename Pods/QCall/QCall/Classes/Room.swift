//
//  Room.swift
//  qcall
//
//  Created by Augusto Alonso on 8/4/20.
//  Copyright © 2020 Augusto Alonso. All rights reserved.
//

import Foundation
import SwiftyJSON
import WebRTC
import AVFoundation

public class Room: RoomDelegate, SignalingClientDelegate {
    public let delegate: RoomDelegate?
    public let localClient: Client
    public let id:String
    public let peerId: String
    public let metadata:JSON
    private let api: API
    private let dataDelegate: DataConnectionDelegate?
    private let videoResolutionConstraints: QVideoResolutionConstraint
    private lazy var rtcClient: RTCClient = {
        return RTCClient(localClient: localClient, signalingDelegate: self, dataConnectionDelegate: dataDelegate, videoResolutionconstraint: videoResolutionConstraints, roomDelegate: self)
    }()
    private var action: (() -> Void)?
    public var cameraPosistion: CameraPosition {
        get { return rtcClient.cameraPosition }
        set {
            rtcClient.cameraPosition = newValue
            rtcClient.switchCamera()
        }
    }
    public var isMuted = false
    {
        willSet{
            self.setIsMute(isMuted: newValue)
        }
    }
    public var isHidden = false
    {
        willSet{
            self.setIsHidden(isHidden: newValue)
        }
    }
    
    
    public var localStream: QMediaStream? {
        get { return rtcClient.localStream }
    }
    public var clients: [Client] = []
    
    
    
    public init(id: String, peerId: String, metadata: JSON, api: API, videoResolutionConstraints: QVideoResolutionConstraint, delegate: RoomDelegate?, dataDelegate: DataConnectionDelegate?) {
        self.id = id
        self.peerId = peerId
        self.metadata = metadata
        self.localClient = Client(id: self.peerId, metadata: metadata)
        self.api = api
        self.dataDelegate = dataDelegate
        self.videoResolutionConstraints = videoResolutionConstraints
        self.delegate = delegate
    }
    
    public func setSpeaker(enabled: Bool){
        let session = AVAudioSession.sharedInstance()
        var _: Error?
        try? session.setCategory(AVAudioSession.Category.playAndRecord)
        try? session.setMode(AVAudioSession.Mode.voiceChat)
        if enabled {
            try? session.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
        } else {
            try? session.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
        }
        try? session.setActive(true)
    }
    
    public func toggleCamera(){
        self.cameraPosistion = cameraPosistion == CameraPosition.back ? .front : .back
    }
    
    public func connect(onSuccess: (([Client]) -> Void)?, onError: (() -> Void)?){
        if clients.isEmpty {
            if !rtcClient.signalingClient.socketOpen {
                action = { self.apiCalls(onSuccess: onSuccess, onError: onError) }
            }else{
                apiCalls(onSuccess: onSuccess, onError: onError)
            }
        }
    }
    
    fileprivate func apiCalls(onSuccess: (([Client]) -> Void)?, onError: (() -> Void)?){
        
        api.registerParticipant(room: self, onSuccess: {
            self.api.getParticipants(room: self, onSuccess: {
                clients in
                //Clients are already filtered in here
                if self.localStream == nil {
                    self.startVideoCapture()
                }
                self.clients = self.rtcClient.connect(callers: clients)
            }, onError: {
                error, code in
                onError?()
            })
        }, onError: {
            error, code in
            onError?()
        })
    
        
    }
    
    public func close(){
        self.clients.forEach {
            client in
            client.conn?.send(json: JSON("{\"CLIENT_DISCONNECTED\": \(self.peerId)}"))
            client.conn?.close()
            client.call?.close()
            self.rtcClient.close()
            api.unregisterParticipant(room: self, onSuccess: {}, onError: {error, code in })
        }
    }
    
    private func setIsMute(isMuted: Bool){
        localStream?.mStream.audioTracks.forEach {
            track in
            track.isEnabled = !isMuted
            self.clients.forEach {
                client in
                client.call?.senders.forEach {
                    sender in
                    if let kind = sender.track?.kind, kind == "audio" {
                        sender.track = track
                    }
                }
            }
        }
    }
    
    private func setIsHidden(isHidden: Bool){
        localStream?.mStream.videoTracks.forEach {
            track in
            track.isEnabled = !isHidden
            self.clients.forEach {
                client in
                client.call?.senders.forEach {
                    sender in
                    if let kind = sender.track?.kind, kind == "video" {
                        sender.track = track
                    }
                }
            }
        }
    }
    
    public func startVideoCapture(){
        rtcClient.startLocalVideoCapture()
    }
    public func startVideoCapture(renderer: QVideoRenderer){
        rtcClient.startLocalVideoCapture(videoRenderer: renderer)
    }
    
    //ROOM EVENTS DELEGATE
    public func roomEvent(localPeerId: String, onLocalStream localStream: QMediaStream) {
        self.delegate?.roomEvent(localPeerId: localPeerId, onLocalStream: localStream)
    }
    
    public func roomEvent(client: Client, onStreamAdded remoteStream: QMediaStream) {
        var i = 0
        var selected = 0
        self.clients.forEach {
            c in
            if c.id == client.id{
                selected = i
                self.clients[i].stream = remoteStream
            }
            i += 1
        }
        DispatchQueue.main.async {
        self.delegate?.roomEvent(client: self.clients[selected], onStreamAdded: remoteStream)
        }
    }
    
    public func roomEvent(onStreamRemoved remotePeerId: String) {
        var i = 0
        self.clients.forEach {
            c in
            if c.id == remotePeerId{
                self.clients[i].stream = nil
            }
            i += 1
        }
        DispatchQueue.main.async {
            self.delegate?.roomEvent(onStreamRemoved: remotePeerId)
            
        }
    }
    
    public func roomEvent(onClientRemoved remotePeerId: String) {
        self.clients = self.clients.filter {
            client in
            return client.id != remotePeerId
        }
        self.delegate?.roomEvent(onClientRemoved: remotePeerId)
    }
    
    public func roomEvent(onStreamDenied error: Error) {
        DispatchQueue.main.async {
            self.delegate?.roomEvent(onStreamDenied: error)
        }
    }
    
    public func onConnectionEstablished() {
        self.delegate?.onConnectionEstablished()
    }
    
    
    //SIGNALING CLIENT DELEGATE
    func signalingClientOpened(_ signalingClient: SignalingClient) {
        action?()
        self.onConnectionEstablished()
    }
    
    func signalingClientClosed(_ signalingClient: SignalingClient) {
//        TODO ADD HANDLER
    }
    
    func signalingClientError(_ signalingClient: SignalingClient, error: Error?) {
        //TODO ADD HANDLER
    }
    
    func onIceCandidateReceived(remotePeerId: String, iceCandidate: RTCIceCandidate, connectionType: ConnectionType) {
        if !(clients.filter { client in  client.id == remotePeerId }.count > 0) {
            let newClient = Client.init(id: remotePeerId, metadata: JSON("{}"))
            clients.append(newClient)
        }
        if let client = clients.first(where: { client in client.id == remotePeerId }) {
            rtcClient.addIceCandidateToMediaConnection(client: client, iceCandidate: iceCandidate, type: connectionType)
        }
        
    }
    
    func onOfferReceived(remotePeerId: String, connectionId: String, metadata: JSON, sdp: RTCSessionDescription, connectionType: ConnectionType) {
        if !(clients.filter { client in  client.id == remotePeerId }.count > 0) {
            let newClient = Client.init(id: remotePeerId, metadata: metadata)
            clients.append(newClient)
        }
        if let client = clients.first(where: { client in client.id == remotePeerId }) {
            rtcClient.onRemoteSessionReceived(client: client, sdp: sdp, verb: .answerer, connectionType: connectionType, connectionId: connectionId)
        }
    }
    
    func onAnswerReceived(remotePeerId: String, metadata: JSON, sdp: RTCSessionDescription, connectionType: ConnectionType) {
        if !(clients.filter { client in  client.id == remotePeerId }.count > 0) {
            let newClient = Client.init(id: remotePeerId, metadata: metadata)
            clients.append(newClient)
        }
        if let client = clients.first(where: { client in client.id == remotePeerId }) {
            rtcClient.onRemoteSessionReceived(client: client, sdp: sdp, verb: .oferrer, connectionType: connectionType)
        }
    }
    
    public func onClientKicked(remotePeerId: String) {
        clients = clients.filter { client in client.id != remotePeerId }
    }
    
    
    public class Builder {
        private var peerId: String = UUID.init().uuidString
        private let deploy: String
        private let key: String
        private let roomId: String
        private var dataDelegate: DataConnectionDelegate?
        private var constraints: QVideoResolutionConstraint = .defaultConstraints
        private var roomDelegate: RoomDelegate?
        private var metadata: JSON = JSON.init("{}")
        
        public init(deploy: String, key: String, roomId: String) {
            self.deploy = deploy
            self.key = key
            self.roomId = roomId
        }
        
        public func setRoomDelegate(delegate: RoomDelegate?) -> Builder{
            self.roomDelegate = delegate
            return self
        }
        
        public func setPeerId(id: String) -> Builder{
            self.peerId = id
            return self
        }
        
        public func setMetadata(json: JSON) -> Builder{
            metadata = json
            return self
        }
        
        public func setVideoResolutionConstraints(constraints: QVideoResolutionConstraint) -> Builder {
            self.constraints = constraints
            return self
        }
        
        public func setMaxVideoResolution(width: Int, height: Int) -> Builder{
            self.constraints.max = QVideoResolution(width: width, height: height)
            return self
        }
        
        public func setMinVideoResolution(width: Int, height: Int) -> Builder{
            self.constraints.min = QVideoResolution(width: width, height: height)
            return self
        }
        
        public func setIdealVideoResolution(width: Int, height: Int) -> Builder{
            self.constraints.ideal = QVideoResolution(width: width, height: height)
            return self
        }
        
        public func setMaxFrameRate(rate: Int) -> Builder{
            self.constraints.frameRateConstraints.max = rate
            return self
        }
        
        public func setMinFrameRate(rate: Int) -> Builder{
            self.constraints.frameRateConstraints.min = rate
            return self
        }
        
        public func setIdealFrameRate(rate: Int) -> Builder{
            self.constraints.frameRateConstraints.ideal = rate
            return self
        }
        
        public func setDataDelegate(delegate: DataConnectionDelegate?) -> Builder {
            self.dataDelegate = delegate
            return self
        }
        
        public func build() -> Room {
            let api = API.init(XAPIKEY: key, deploy: deploy)
            return Room.init(id: roomId, peerId: peerId, metadata: metadata, api: api, videoResolutionConstraints: constraints, delegate: roomDelegate, dataDelegate: dataDelegate)
        }
        
    }
}

