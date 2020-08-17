//
//  SignalingClient.swift
//  qcall
//
//  Created by Augusto Alonso on 8/5/20.
//  Copyright © 2020 Augusto Alonso. All rights reserved.
//

import Foundation
import Starscream
import SwiftyJSON
import WebRTC

class SignalingClient: Starscream.WebSocketDelegate {
    var socketOpen = false
    private lazy var socket: WebSocket = {
        let url = URL(string: "\(self.WsUrl)&id=\(peerId)")!
        let request = URLRequest(url: url)
        let socket = WebSocket(request: request)
        socket.delegate = self
        return socket
    }()
    
    var timer: Timer?
    private let peerId : String
    var secure = true
    fileprivate var host = "webrtc.schoolaid.app"
    fileprivate var port = 443
    fileprivate var key = "peerjs"
    fileprivate var token = "peerjs"
    fileprivate var path = "/myapp"
    var delegate: SignalingClientDelegate?
    
    fileprivate var WsUrl: String {
        let proto = self.secure ? "wss" : "ws"

        let urlStr = "\(proto)://\(self.host):\(self.port)\(self.path)/peerjs?key=\(self.key)&token=\(self.token)"
        return urlStr
    }
    
    init(peerId: String) {
        self.peerId = peerId
        self.connect()
    }
    
    deinit {
        self.close()
    }
    
    func connect(){
        self.socket.connect()
    }
    
    func close(){
        self.socket.disconnect(closeCode: 100)
    }
    
    fileprivate func ping() {
        let message: [String: Any] = [
            "type": "HEARTBEAT"
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: message, options: []) else { return }
        self.socket.write(data: data)
    }
    
    func send(string: String, onCompletition: (()->())? = nil) {
        self.socket.write(string: string, completion: onCompletition)
    }
    
    func send(data: Data, onCompletition: (()->())? = nil) {
        self.socket.write(data: data, completion: onCompletition)
    }
    
    func send(json: JSON, onCompletition: (()->())? = nil) {
        do {
            try self.socket.write(data: json.rawData(), completion: onCompletition)
        } catch {
            //Failed
        }
    }
    
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected( _):
            self.socketOpen = true
            Timer.scheduledTimer(withTimeInterval: 18, repeats: true) { timer in
                self.ping()
            }
            self.delegate?.signalingClientOpened(self)
        case .disconnected(let reason, let code):
            socketOpen = false
            self.delegate?.signalingClientClosed(self)
            print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let text):
            self.handleMessage(text)
        case.binary(let data):
            print("data: \(data.base64EncodedString())")
        case .cancelled:
            self.delegate?.signalingClientClosed(self)
        case.error(let error):
            self.delegate?.signalingClientError(self, error: error)
        default:
            print("NEW EVENT")
        }
    }
    
    fileprivate func handleMessage(_ text: String) {
        let messageString = text
        
        guard let data = messageString.data(using: String.Encoding.utf8) else {
            return
        }
        guard let message = (try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)) as? [String: Any] else {
            return
        }
        
        guard let typeRaw = message["type"] as? String else {
            print("ERROR: type doesn't exist")
            return
        }
        
        let type = SignalingClientEvents.init(rawValue: typeRaw)
        switch type {
        case .iceCandidateReceived:
            guard let remotePeerId = message["src"] as? String else { return }
            guard let payload = message["payload"] as? [String: Any] else { return }
            guard let payloadType = payload["type"] as? String else { return }
            
            guard let candidateJson = payload["candidate"] as? [String: Any] else { return }
            guard let candidate = candidateJson["candidate"] as? String else {
                print("ERROR: candidate is nil")
                return
            }
            
            guard let sdpMLineIndex = candidateJson["sdpMLineIndex"] as? Int else {
                print("ERROR: sdpMLineIndex is nil")
                return
            }
            
            guard let sdpMid = candidateJson["sdpMid"] as? String else {
                print("ERROR: sdpMid is nil")
                return
            }
            let iceCandidate = RTCIceCandidate(sdp: candidate, sdpMLineIndex: Int32(sdpMLineIndex), sdpMid: sdpMid)
            self.delegate?.onIceCandidateReceived(remotePeerId: remotePeerId, iceCandidate: iceCandidate, connectionType: self.getConnectionType(type: payloadType))
        case .offerReceived:
            guard let remotePeerId = message["src"] as? String else { return }
            guard let payload = message["payload"] as? [String: Any] else { return }
            guard let payloadType = payload["type"] as? String else { return }
            guard let connectionId = payload["connectionId"] as? String else { return }
            guard let metadataString = payload["metadata"] as? [String: Any]? else { return }
            var metadata: JSON
            if let metadataString =  metadataString {
                metadata = JSON(metadataString)
//                metadata = JSON.init(parseJSON: metadataString)
            }else{
                metadata = JSON.init(parseJSON: "{}")
            }
            guard let jsonSdpHolder = payload["sdp"] as? [String: Any] else { return }
            guard var sdpMessage = jsonSdpHolder["sdp"] as? String else { return }
            //remove double header
            sdpMessage = sdpMessage.replacingOccurrences(of: "RTCSessionDescription:\noffer\n", with: "")
            sdpMessage = sdpMessage.replacingOccurrences(of: "RTCSessionDescription:\nanswer\n", with: "")
            let sdp = RTCSessionDescription(type: .offer, sdp: sdpMessage)
            self.delegate?.onOfferReceived(remotePeerId: remotePeerId, connectionId: connectionId, metadata: metadata, sdp: sdp, connectionType: self.getConnectionType(type: payloadType))
        case .answerReceived:
            guard let remotePeerId = message["src"] as? String else { return }
            guard let payload = message["payload"] as? [String: Any] else { return }
            guard let payloadType = payload["type"] as? String else { return }
            
            guard let metadataString = payload["metadata"] as? String? else { return }
            var metadata: JSON
            if let metadataString =  metadataString {
                metadata = JSON.init(parseJSON: metadataString)
            }else{
                metadata = JSON.init(parseJSON: "{}")
            }
            guard let jsonSdpHolder = payload["sdp"] as? [String: Any] else { return }
            guard var sdpMessage = jsonSdpHolder["sdp"] as? String else { return }
            //remove double header
            sdpMessage = sdpMessage.replacingOccurrences(of: "RTCSessionDescription:\noffer\n", with: "")
            sdpMessage = sdpMessage.replacingOccurrences(of: "RTCSessionDescription:\nanswer\n", with: "")
            let sdp = RTCSessionDescription(type: .answer, sdp: sdpMessage)
            self.delegate?.onAnswerReceived(remotePeerId: remotePeerId, metadata: metadata, sdp: sdp, connectionType: self.getConnectionType(type: payloadType))
        case .clientKicked:
            guard let remotePeerId = message["peerId"] as? String else { return }
            self.delegate?.onClientKicked(remotePeerId: remotePeerId)
        case .none:
            print("Error this should not hapen")
        }
        
        
        
    }
    
    fileprivate func getConnectionType(type: String) -> ConnectionType {
        if type == "media" {
            return ConnectionType.media
        }else{
            return ConnectionType.data
        }
    }
    
    
}
