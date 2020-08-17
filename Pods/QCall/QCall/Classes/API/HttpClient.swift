//
//  HttpClient.swift
//  qcall
//
//  Created by Augusto Alonso on 8/5/20.
//  Copyright © 2020 Augusto Alonso. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire

enum HttpClientCodes : Int {
    case timeOut = 10001, noConnection = 10002, unknownError = 999999
}
class HttpClient {
    typealias SuccessCallback = (JSON) -> Void
    typealias ErrorCallback = (Int, JSON?) -> Void
    
    static let baseURL: (String) -> String = {
        deploy in
        return "https://6wnvsov233.execute-api.us-east-2.amazonaws.com/\(deploy)/room-participants"
    }
    fileprivate static func request(_ url: String, method: HTTPMethod, apiKey: String?, parameters: [String: Any] = [:]) -> DataRequest {
        
        var headers: HTTPHeaders = [:]
        headers.add(name: "Accept", value: "application/json")
        headers.add(name: "Content-Type", value: "application/json")
        if let apiKey = apiKey {
            headers.add(name: "X-API-KEY", value: apiKey)
        }
        
        return AF.request(
            url,
            method: method,
            parameters: parameters,
            encoding: JSONEncoding.default,
            headers: headers
        ){
            urlRequest in
            urlRequest.timeoutInterval = 20
        }
    }
    
    static func handleRequest(_ url: String, method: HTTPMethod, parameters: [String: Any] = [:], apiKey: String?,
                              onSuccess: SuccessCallback? = nil, onError: ErrorCallback? = nil) {
        let dataRequest = request(url, method: method, apiKey: apiKey, parameters: parameters)
        handleResponseJson(dataRequest: dataRequest, onSuccess: onSuccess, onError: onError)
    }
    
    static private func handleResponseJson(dataRequest: DataRequest, onSuccess: SuccessCallback? = nil, onError: ErrorCallback? = nil){
        dataRequest.responseJSON { response in
            switch response.result {
            case .failure(let error):
                if response.response != nil {
                    if let onErrorHandler = onError {
                        onErrorHandler(HttpClientCodes.unknownError.rawValue, nil)
                    }
                }else {

                    if let onErrorHandler = onError{
                        onErrorHandler(0, nil)
                    }
                    if let underlyingError = error.underlyingError {
                        if let urlError = underlyingError as? URLError {
                            switch urlError.code {
                            case .timedOut:
                                onError?(HttpClientCodes.timeOut.rawValue, nil)
                                
                            case .notConnectedToInternet:
                                onError?(HttpClientCodes.noConnection.rawValue, nil)
                            default:
                                onError?(HttpClientCodes.unknownError.rawValue, nil)
                            }
                        }
                    }
                    
                }
            case .success:
                if let httpResponse = response.response {
                    if(httpResponse.statusCode == 200) {
                        if let data = response.data {
                            do {
                                let json = try JSON(data: data)
                                onSuccess?(json)
                            } catch {
                                onError?(100, nil)
                            }
                        }
                    }else if httpResponse.statusCode == 504 {
                        onError?(HttpClientCodes.timeOut.rawValue, nil)
                    } else {
                        if let errorHandler = onError {
                            if let data = response.data {
                                do {
                                    let json = try JSON(data: data)
                                    errorHandler(httpResponse.statusCode, json)
                                } catch {
                                    
                                    errorHandler(httpResponse.statusCode, nil)
                                }
                                
                            }else {
                                errorHandler(httpResponse.statusCode, nil)
                            }
                            
                        } else {
                            if let onErrorHandler = onError {
                                onErrorHandler(HttpClientCodes.unknownError.rawValue, nil)
                            }
                        }
                    }
                }
                
            }
            
        }
    }
}

