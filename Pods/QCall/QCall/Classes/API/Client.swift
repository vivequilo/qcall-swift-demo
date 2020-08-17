//
//  Client.swift
//  qcall
//
//  Created by Augusto Alonso on 8/5/20.
//  Copyright © 2020 Augusto Alonso. All rights reserved.
//

import Foundation
import SwiftyJSON

public struct Client: Decodable {
    let id: String
    let metadata: JSON
    var call: MediaConnection?
    var conn: DataConnection?
    var stream: QMediaStream?
    private enum CodingKeys: String, CodingKey {
        case id = "peer_id", metadata = "metadata"
    }
    
}
