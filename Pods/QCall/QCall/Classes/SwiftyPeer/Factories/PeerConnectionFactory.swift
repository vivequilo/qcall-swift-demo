//
//  PeerConnectionFactory.swift
//  PeerClient
//
//  Created by Akira Murao on 10/22/15.
//  Copyright © 2017 Akira Murao. All rights reserved.
//

import Foundation
import WebRTC

class PeerConnectionFactory {

    
    
    var videoCapturer: RTCCameraVideoCapturer?
    
    let videoResolutionConstraints: QVideoResolutionConstraint
    let videoTrackId = "\(UUID.init().uuidString)v0"
    let audioTrackId = "\(UUID.init().uuidString)a0"
    let streamId = "\(UUID.init().uuidString)"
    var factory: RTCPeerConnectionFactory
    
    
    init(videoResolutionConstraints: QVideoResolutionConstraint) {
        RTCInitializeSSL()
        self.videoResolutionConstraints = videoResolutionConstraints
        self.factory = RTCPeerConnectionFactory()
        
    }
    
    deinit {
        RTCCleanupSSL()
    }
    
    
    func createPeerConnection(_ connectionType: ConnectionType, iceServers: [RTCIceServer], delegate: RTCPeerConnectionDelegate?) -> RTCPeerConnection? {
        print("Creating RTCPeerConnection.")
        
        let constraints = self.defaultPeerConnectionConstraints(connectionType)
        let config = RTCConfiguration()
        config.iceServers = iceServers
        let pc = self.factory.peerConnection(with: config, constraints: constraints, delegate: delegate)
        return pc
    }

    func createLocalMediaStream() -> QMediaStream? {

        let stream = self.factory.mediaStream(withStreamId: streamId)
        
        stream.addVideoTrack(self.createLocalVideoTrack())
        
        let localAudioTrack = self.factory.audioTrack(withTrackId: audioTrackId)
        stream.addAudioTrack(localAudioTrack)
        
        return QMediaStream.init(stream: stream)
    }

    // MARK: Private

    private func defaultPeerConnectionConstraints(_ connectionType: ConnectionType) -> RTCMediaConstraints {

        if connectionType == .data {
            return RTCMediaConstraints.init(mandatoryConstraints: nil, optionalConstraints: nil)
        }
        else if connectionType == .media {
            let optionalConstraints = ["DtlsSrtpKeyAgreement":"true"]
            let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: optionalConstraints)
            return constraints
        }
        return RTCMediaConstraints.init(mandatoryConstraints: nil, optionalConstraints: nil)
    }

    
    
    func createLocalVideoTrack(position: CameraPosition = .front) -> RTCVideoTrack {
        let videoSource = self.factory.videoSource()
        
        self.videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
        let cameraPosition = position == .front ? AVCaptureDevice.Position.front : AVCaptureDevice.Position.back
        var selectedDevice: AVCaptureDevice?
        for device in RTCCameraVideoCapturer.captureDevices(){
            if device.position == cameraPosition{
                selectedDevice = device
            }
        }
        if let selectedDevice = selectedDevice {
            self.videoCapturer?.startCapture(with: selectedDevice,
                                             format: selectedDevice.formats[0],
                                             fps: self.videoResolutionConstraints.frameRateConstraints.ideal,
                                             completionHandler: nil)
        }
        
        let videoTrack = self.factory.videoTrack(with: videoSource, trackId: "ARDAMSv0")
        return videoTrack
    }
    
    
}


