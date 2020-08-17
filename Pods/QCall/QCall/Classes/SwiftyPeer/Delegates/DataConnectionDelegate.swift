//
//  DataConnectionDelegate.swift
//  qcall
//
//  Created by Augusto Alonso on 8/7/20.
//  Copyright © 2020 Augusto Alonso. All rights reserved.
//

import Foundation
import SwiftyJSON
public protocol DataConnectionDelegate: class {
    func onDataConnectionOpen()
//    func onConnectingDataChannel()
    func onDataConnectionClosed()
    func message(onMessageFailed error : String)
    func message(onDataJson json : JSON)
    func message(onDataString message : String)
}

