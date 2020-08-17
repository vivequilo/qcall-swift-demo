//
//  API.swift
//  qcall
//
//  Created by Augusto Alonso on 8/5/20.
//  Copyright © 2020 Augusto Alonso. All rights reserved.
//

import Foundation
import SwiftyJSON
public class API {
    
    private struct RoomRequestBody: Encodable {
        let action: String
        let roomId: String
        let metadata: JSON
    }
    
    enum Error {
        case badEncoding, badRequest
    }
    
    let XAPIKEY: String
    let deploy: String
    let url: String
    
    
    init(XAPIKEY:String, deploy: String) {
        self.XAPIKEY = XAPIKEY
        self.deploy = deploy
        self.url = HttpClient.baseURL(deploy)
    }
    
    
    private func getBody(room: Room, action:String) -> [String : Any]{
        return [
            "action" : action,
            "room_id" : room.id,
            "peer_id" : room.peerId,
            "metadata" : room.metadata.dictionaryObject ??  [:]
        ]
    }
    
    func getParticipants(room: Room, onSuccess: @escaping ([Client]) -> Void, onError: @escaping (API.Error, Int) -> Void ) {
        HttpClient.handleRequest(
            self.url,
            method: .post,
            parameters: self.getBody(room: room, action: "list"),
            apiKey: XAPIKEY,
            onSuccess: {
                json in
                do {
                    let clients = try JSONDecoder().decode([Client].self, from: json["participants"].rawData())
                    onSuccess(clients.filter { it in it.id != room.peerId })
                }catch{
                    onError(.badEncoding, 0)
                }
            },
            onError: {
                code, json in
                onError(.badRequest, code)
            }
        )
    }
    
    func registerParticipant(room: Room, onSuccess: @escaping () -> Void, onError: @escaping (API.Error, Int) -> Void ) {
        HttpClient.handleRequest(
            self.url,
            method: .post,
            parameters: self.getBody(room: room, action: "register"),
            apiKey: XAPIKEY,
            onSuccess: {
                json in
                onSuccess()
            },
            onError: {
                code, json in
                print(json?["message"] ?? "lolito")
                onError(.badRequest, code)
            }
        )
    }
    
    func unregisterParticipant(room: Room, onSuccess: @escaping () -> Void, onError: @escaping (API.Error, Int) -> Void ) {
        HttpClient.handleRequest(
            self.url,
            method: .post,
            parameters: self.getBody(room: room, action: "unregister"),
            apiKey: XAPIKEY,
            onSuccess: {
                json in
                onSuccess()
            },
            onError: {
                code, json in
                onError(.badRequest, code)
            }
        )
    }

    
}
