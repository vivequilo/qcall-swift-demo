//
//  BaseConnection.swift
//  qcall
//
//  Created by Augusto Alonso on 8/6/20.
//  Copyright © 2020 Augusto Alonso. All rights reserved.
//

import Foundation
import WebRTC
import SwiftyJSON

public class BaseConnection: NSObject {
    
    let client : Client
    let localClient : Client
    let signalingClient : SignalingClient
    let connectionType : ConnectionType
    let resolutionConstraints: QVideoResolutionConstraint
    var connectionVerb : ConnectionVerb
    var queuedIceCandidates: [RTCIceCandidate] = []
    
    var prefix : String {
        return connectionType.prefix()
    }
    var peerConnection: RTCPeerConnection? {
        didSet {
            print("PeerConnection pc: \(String(describing: self.peerConnection))")
        }
    }
    
    var senders: [RTCRtpSender] {
        return self.peerConnection?.senders ?? []
    }
    
    var connectionId: String?
    {
        didSet{
            onConnectionIdSet()
        }
    }
    
    
    private var localDescriptionSet: Bool = false {
        didSet {
            if connectionVerb == .answerer {
                if localDescriptionSet {
                    self.drainCandidates()
                }
            }
        }
    }
    
    
    init(connectionType: ConnectionType, connectionVerb: ConnectionVerb, signalingClient: SignalingClient, client: Client,
         localClient: Client, resolutionConstraints: QVideoResolutionConstraint) {
        self.connectionType = connectionType
        self.connectionVerb = connectionVerb
        self.signalingClient = signalingClient
        self.client = client
        self.localClient = localClient
        self.resolutionConstraints = resolutionConstraints
    }
    
    
    func addStream(stream: QMediaStream){
        peerConnection?.add(stream.mStream)
    }
    
    func call(){
        let constraints = RTCMediaConstraints(mandatoryConstraints: getConstraintsSet(), optionalConstraints: nil)
        self.connectionId = "\(prefix)\(UUID.init().uuidString)"
        var didThrowError = false
        var errorMessage = ""
        peerConnection?.offer(for: constraints) {
            (sdp, error) in
            guard let sdp = sdp
            else {
                didThrowError = true
                errorMessage = error?.localizedDescription ?? "Error creating offer"
                return
            }
            self.peerConnection?.setLocalDescription(sdp) {
                error in
                if let error = error {
                    didThrowError = true
                    errorMessage = error.localizedDescription
                }else{
                    self.sendLocalDescription(sdp: sdp)
                    self.drainCandidates()
                }
            }
        }
        if didThrowError {
            print("Error sending answer ", errorMessage)
        }
    }
    
    func answer() {
        let constraints = RTCMediaConstraints(mandatoryConstraints: getConstraintsSet(), optionalConstraints: nil)
        var didThrowError = false
        var errorMessage = ""
        peerConnection?.answer(for: constraints) {
            sdp, error in
            guard let sdp = sdp
            else {
                didThrowError = true
                errorMessage = error?.localizedDescription ?? "Error creating answer"
                return
            }
            self.peerConnection?.setLocalDescription(sdp) {
                error in
                if let error = error {
                    didThrowError = true
                    errorMessage = error.localizedDescription
                }else{
                    self.sendLocalDescription(sdp: sdp)
                    self.localDescriptionSet = true
                }
            }
        }
        
        if didThrowError {
            print("Error sending answer ", errorMessage)
        }
    }
    
    func setRemoteDescription(sdp: RTCSessionDescription, connectionId: String?){
        
        peerConnection?.setRemoteDescription(sdp) {
            error in
            if let error = error  {
                print("error ", error.localizedDescription)
                return
            }
            if self.connectionVerb == .answerer{
                if let connectionId = connectionId {
                    self.connectionId = connectionId
                    self.onConnectionIdSet()
                    self.answer()
                }
            }
        }
    }
    
    fileprivate func sendLocalDescription(sdp: RTCSessionDescription){
        var type: String
        switch sdp.type {
        case .answer:
            type = "answer"
        case.offer:
            type = "offer"
        default:
            type = "answer"
        }
        
        let sdpJson: [String: String] = [
            "sdp" : sdp.description.replacingOccurrences(of: "RTCSessionDescription:\noffer\n", with: "").replacingOccurrences(of: "RTCSessionDescription:\nanswer\n", with: ""),
            "type" : type
        ]
        
        var metadataHolder  = self.localClient.metadata.dictionaryObject ?? [:]
        
        metadataHolder["id"] = localClient.id
        
        let payload: [String:Any?] = [
            "connectionId" : self.connectionId,
            "sdp" : sdpJson,
            "type" : self.connectionType.rawValue,
            "browser" : "chrome",
            "metadata" : JSON(metadataHolder),
        ]
        
        var localDescription : [String:Any] = [
            "type": type.uppercased(),
            "dst": self.client.id,
            "src" : self.localClient.id,
            "payload" : payload
        ]
        if sdp.type == .offer {
            localDescription["reliable"] = false
        }
        
        
        self.signalingClient.send(json: JSON(localDescription))
    }
    
    func addIcecandidate(iceCandidate: RTCIceCandidate){
        if connectionVerb == .answerer {
            if localDescriptionSet {
                self.sendIceCandidate(iceCandidate: iceCandidate)
                self.peerConnection?.add(iceCandidate)
            }else{
                self.queuedIceCandidates.append(iceCandidate)
            }
        }else {
            self.sendIceCandidate(iceCandidate: iceCandidate)
            self.peerConnection?.add(iceCandidate)
        }
    }
    
    fileprivate func drainCandidates(){
        queuedIceCandidates.forEach {
            candidate in
            peerConnection?.add(candidate)
            sendIceCandidate(iceCandidate: candidate)
        }
    }
    
    fileprivate func sendIceCandidate(iceCandidate: RTCIceCandidate?){
        if let iceCandidate = iceCandidate {
            if let connectionId = self.connectionId {
                let iceCandidateInfo: [String: Any?] = [
                    "type": "CANDIDATE",
                    "payload" : [
                        "candidate": [
                            "sdpMid" : iceCandidate.sdpMid ?? "0",
                            "sdpMLineIndex" : iceCandidate.sdpMLineIndex,
                            "candidate" : iceCandidate.sdp,
                        ],
                        "type": self.connectionType.rawValue,
                        "connectionId": connectionId,
                    ],
                    "dst" : self.client.id,
                    "src" : self.localClient.id,
                ]
                
                self.signalingClient.send(json: JSON(iceCandidateInfo))
            }
        }
    }
    
    func close(){
        peerConnection?.close()
    }
    
    internal func onConnectionIdSet() {
        
    }
    
    fileprivate func getConstraintsSet() -> [String : String]{
        return [
            "OfferToReceiveVideo" : "true",
            "OfferToReceiveAudio" : "true",
            "minWidth" : resolutionConstraints.min.width.description,
            "minHeight" : resolutionConstraints.min.height.description,
            "maxWidth" : resolutionConstraints.max.width.description,
            "maxHeight" : resolutionConstraints.max.height.description,
            "idealWidth" : resolutionConstraints.ideal.width.description,
            "idealHeight" : resolutionConstraints.ideal.width.description,
            "minFrameRate" : resolutionConstraints.frameRateConstraints.min.description,
            "maxFrameRate" : resolutionConstraints.frameRateConstraints.max.description,
            "idealFrameRate" : resolutionConstraints.frameRateConstraints.ideal.description,
        ]
    }
}


