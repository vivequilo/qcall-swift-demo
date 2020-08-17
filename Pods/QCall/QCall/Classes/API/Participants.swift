//
//  Participants.swift
//  qcall
//
//  Created by Augusto Alonso on 8/5/20.
//  Copyright © 2020 Augusto Alonso. All rights reserved.
//

import Foundation

public struct Participants: Decodable {
    let participants: [Client]
    
    private enum CodingKeys: String, CodingKey {
        case participants = "participants"
    }
}
