//
//  DataConnection.swift
//  qcall
//
//  Created by Augusto Alonso on 8/7/20.
//  Copyright © 2020 Augusto Alonso. All rights reserved.
//

import Foundation
import WebRTC
import SwiftyJSON

public class DataConnection: BaseConnection, RTCDataChannelDelegate, RTCPeerConnectionDelegate {

    var roomDelegate: RoomDelegate
    var delegate: DataConnectionDelegate?
    var isOpen = false
    var isClosed: Bool {
        return !isOpen
    }
    var dataChannel: RTCDataChannel?
    
    init(roomDelegate : RoomDelegate, connectionVerb: ConnectionVerb, signalingClient: SignalingClient, client: Client, localClient: Client, resolutionConstraints: QVideoResolutionConstraint) {
        self.roomDelegate = roomDelegate
        super.init(connectionType: .data, connectionVerb: connectionVerb, signalingClient: signalingClient, client: client, localClient: localClient, resolutionConstraints: resolutionConstraints)
    }
    
    
    
    override func onConnectionIdSet() {
        if connectionVerb == .answerer {
            if let connectionId = connectionId {
                if dataChannel == nil {
                    dataChannel = peerConnection?.dataChannel(forLabel: connectionId, configuration: RTCDataChannelConfiguration.init())
                }
            }
        }
    }
    
    public func send(message:String){
        if let data = message.data(using: .utf8){
            dataChannel?.sendData(RTCDataBuffer(data: data, isBinary: false))
        }
    }
    
    public func send(json:JSON){
        do {
            let data = try json.rawData()
            dataChannel?.sendData(RTCDataBuffer(data: data, isBinary: false))
        }catch {
            print("Could not parse json")
        }
    }
    
    public func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        switch dataChannel.readyState {
        case .closed:
            self.isOpen = false
            delegate?.onDataConnectionClosed()
        case .open:
            self.isOpen = true
            delegate?.onDataConnectionOpen()
        case .connecting:
            print("Data connection connecting")
        case .closing:
            print("Closing")
        default:
            print("Unhandled state")
        }
    }
    
    public func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        let messageString  = String.init(data: buffer.data, encoding: .utf8)
        if let messageString = messageString {
            
                let messageJson = JSON(parseJSON: messageString)
                if !messageJson.isEmpty{
                    if messageString.contains("type") && messageString.contains(DataMessageType.clientDisconnected.rawValue){
                        roomDelegate.roomEvent(onClientRemoved: client.id)
                    }else{
                        delegate?.message(onDataString: messageString)
                    }
                }else{
                    if messageString.contains("type") && messageString.contains(DataMessageType.clientDisconnected.rawValue){
                        roomDelegate.roomEvent(onClientRemoved: client.id)
                    }else{
                        delegate?.message(onDataString: messageString)
                    }
                }
                if messageJson["type"].exists() && messageJson["type"].description == DataMessageType.clientDisconnected.rawValue {
                    roomDelegate.roomEvent(onClientRemoved: client.id)
                }else{
                    delegate?.message(onDataJson: messageJson)
                }
        }

    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
    }
    
    public func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
//        TODO Re neggotiate the connection
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        //ADD MORE HANDLERS
        print("new ice connection state ", newState.rawValue)
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        //ADD MORE HANDLERS
        print("new ice gathering state ", newState.rawValue)
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        self.addIcecandidate(iceCandidate: candidate)
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        //Add more handlers
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        self.dataChannel = dataChannel
    }
    

}

