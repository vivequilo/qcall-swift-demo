//
//  RoomDelegate.swift
//  qcall
//
//  Created by Augusto Alonso on 8/7/20.
//  Copyright © 2020 Augusto Alonso. All rights reserved.
//

import Foundation
import WebRTC
public protocol RoomDelegate: class {
    func roomEvent(localPeerId : String, onLocalStream localStream: QMediaStream)
    func roomEvent(client : Client, onStreamAdded remoteStream: QMediaStream)
    func roomEvent(onStreamRemoved remotePeerId : String)
    func roomEvent(onClientRemoved remotePeerId: String)
    func roomEvent(onStreamDenied error: Error)
    func onConnectionEstablished()
}

