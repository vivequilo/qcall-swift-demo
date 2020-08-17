//
//  SignalingClientDelegate.swift
//  qcall
//
//  Created by Augusto Alonso on 8/5/20.
//  Copyright © 2020 Augusto Alonso. All rights reserved.
//

import Foundation
import WebRTC
import SwiftyJSON
protocol SignalingClientDelegate: class {
    func signalingClientOpened(_ signalingClient: SignalingClient)
    func signalingClientClosed(_ signalingClient: SignalingClient)
    func signalingClientError(_ signalingClient: SignalingClient, error: Error?)
    func onIceCandidateReceived(remotePeerId: String, iceCandidate: RTCIceCandidate, connectionType: ConnectionType)
    func onOfferReceived(remotePeerId: String, connectionId: String, metadata: JSON, sdp: RTCSessionDescription, connectionType: ConnectionType)
    func onAnswerReceived(remotePeerId: String, metadata: JSON, sdp: RTCSessionDescription, connectionType: ConnectionType)
    func onClientKicked(remotePeerId: String)
}

