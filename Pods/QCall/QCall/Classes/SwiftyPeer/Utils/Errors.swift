//
//  Errors.swift
//  qcall
//
//  Created by Augusto Alonso on 8/6/20.
//  Copyright © 2020 Augusto Alonso. All rights reserved.
//

import Foundation

public enum SdpError : Error {
    case offerFailed(String)
    case answerFailed(String)
}

