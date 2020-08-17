//
//  Enums.swift
//  qcall
//
//  Created by Augusto Alonso on 8/5/20.
//  Copyright © 2020 Augusto Alonso. All rights reserved.
//

import Foundation

enum SignalingClientEvents: String {
    case iceCandidateReceived = "CANDIDATE"
    case offerReceived = "OFFER"
    case answerReceived = "ANSWER"
    case clientKicked = "CLIENT_DISCONNECTED"
}

enum ConnectionType : String {
    case media = "media"
    case data = "data"
    func prefix() -> String {
        switch self {
        case .media:
            return "mc_"
        default:
            return "dc_"
        }
    }
}


enum ConnectionVerb {
    case answerer, oferrer
}

enum DataMessageType : String {
    case clientDisconnected = "CLIENT_DISCONNECTED"
}

public enum CameraPosition {
    case front, back
    
    public mutating func toggle(){
        if self == .front {
            self = .back
        }else{
            self = .front
        }
    }
}


