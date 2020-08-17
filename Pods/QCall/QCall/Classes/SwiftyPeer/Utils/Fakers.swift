//
//  Fakers.swift
//  qcall
//
//  Created by Augusto Alonso on 8/6/20.
//  Copyright © 2020 Augusto Alonso. All rights reserved.
//

import Foundation
import WebRTC



public class QVideoRenderer: UIView {
    public var renderView: RTCEAGLVideoView?
    public var track: QVideoTrack?
    {
        didSet {
            if track != nil {
                self.initView()
                track?.add(renderer: self)
            }else{
                renderView?.removeFromSuperview()
                renderView = nil
            }
        }
    }
    
    fileprivate func initView(){
        renderView?.removeFromSuperview()
        renderView = nil
        renderView = RTCEAGLVideoView()
        if let renderView = self.renderView {
            addSubview(renderView)
            renderView.translatesAutoresizingMaskIntoConstraints = false
            renderView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
            renderView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
            renderView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
            renderView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        }
        
    }
    
    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    public var mirrored: Bool = false
    {
        didSet {
            if mirrored {
                self.transform = .init(scaleX: -1, y: 1)
            }else{
                self.transform = .init(scaleX: 1, y: 1)
            }
            
        }
    }
    
    public func removeCurrentTrack() {
        if let track = self.track {
            
            track.remove(renderer: self)
            self.track = nil
        }
    }
}



public class QVideoTrack {
    public let track: RTCVideoTrack
    public var renderer: QVideoRenderer?
    public var id: String {
        return track.trackId
    }
    public var enabled: Bool {
        get { return track.isEnabled }
        set { track.isEnabled = newValue }
    }
    public var kind: String {
        return track.kind
    }
    
    public var state: RTCMediaStreamTrackState {
        return track.readyState
    }
    
    
    public init(track: RTCVideoTrack) {
        self.track = track
    }
    
    public func add(renderer: QVideoRenderer){
        self.renderer = renderer
        if let renderer = renderer.renderView{
            track.add(renderer)
        }
    }
    
    public func remove(renderer: QVideoRenderer){
        self.renderer = nil
        if let renderer = renderer.renderView{
            track.remove(renderer)
        }
        
    }
    
}


public class QAudioTrack {
    public let track: RTCAudioTrack
    public var id: String {
        return track.trackId
    }
    public var enabled: Bool {
        get { return track.isEnabled }
        set { track.isEnabled = newValue }
    }
    public var kind: String {
        return track.kind
    }
    
    public var state: RTCMediaStreamTrackState {
        return track.readyState
    }
    
    public var volume: Double {
        get { track.source.volume }
        set { track.source.volume = newValue }
    }
    
    
    public init(track: RTCAudioTrack) {
        self.track = track
    }
}

public class QMediaStream {
    public let mStream : RTCMediaStream
    public var audioTracks: [QAudioTrack]
    public var videoTracks: [QVideoTrack]

    
    public var id: String {
       return mStream.streamId
    }
    
    public func addAudioTrack(track: QAudioTrack){
        mStream.addAudioTrack(track.track)
        self.audioTracks.append(track)
    }
    
    public func addVideoTrack(track: QVideoTrack){
        mStream.addVideoTrack(track.track)
        self.videoTracks.append(track)
    }
    
    public func removeAudioTrack(track: QAudioTrack){
        mStream.removeAudioTrack(track.track)
        self.audioTracks.removeAll {
            atrack in
            return atrack.id == track.id
        }
    }
    
    public func removeVideoTrack(track: QVideoTrack){
        mStream.removeVideoTrack(track.track)
        self.videoTracks.removeAll {
            vtrack in
            return vtrack.id == track.id
        }
    }
    
    public init(stream : RTCMediaStream) {
        self.mStream = stream
        self.audioTracks = mStream.audioTracks.map { track in return QAudioTrack(track: track) }
        self.videoTracks = mStream.videoTracks.map { track in return QVideoTrack(track: track) }
    }
}

public struct QVideoResolution {
    public let width: Int
    public let height: Int
    public static let fullHD: QVideoResolution = .init(width: 1920, height: 1080)
    public static let HD: QVideoResolution = .init(width: 1280, height: 720)
    public static let SD: QVideoResolution = .init(width: 640, height: 480)
    public static let LOW: QVideoResolution = .init(width: 480, height: 360)
    public static let screenResolution: QVideoResolution = {
        let bounds = UIScreen.main.bounds
        return QVideoResolution(width: Int(bounds.width), height: Int(bounds.height))
    }()
}

public struct QVideoFrameRateConstraints {
    public var min: Int
    public var max: Int
    public var ideal: Int
    public static let low = 15
    public static let standard = 25
    public static let good = 30
    public static let high = 45
    public static let max = 60
    static let defaultFrameRates: QVideoFrameRateConstraints = .init(min: QVideoFrameRateConstraints.low, max: QVideoFrameRateConstraints.standard, ideal: QVideoFrameRateConstraints.good)
}


public struct QVideoResolutionConstraint {
    public var min: QVideoResolution
    public var max: QVideoResolution
    public var ideal: QVideoResolution
    public var frameRateConstraints: QVideoFrameRateConstraints
    
    public static let defaultConstraints: QVideoResolutionConstraint = .init(min: .LOW, max: .HD, ideal: .SD, frameRateConstraints: .defaultFrameRates)
}

