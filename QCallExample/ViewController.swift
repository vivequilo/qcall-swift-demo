//
//  ViewController.swift
//  QCallExample
//
//  Created by Augusto Alonso on 8/17/20.
//  Copyright © 2020 Augusto Alonso. All rights reserved.
//

import UIKit
import QCall
import SwiftyJSON

class ViewController: UIViewController, RoomDelegate {

    var speakerOn =  false
    lazy var localView: QVideoRenderer = {
        return QVideoRenderer()
    }()
    
    lazy var remoteView: QVideoRenderer = {
        return QVideoRenderer()
    }()
    
    lazy var button : UIButton = {
        let button = UIButton()
        button.setTitle("Empezar a grabar tu vista", for: .normal)
        button.backgroundColor = .brown
        button.isEnabled = true
        button.heightAnchor.constraint(equalToConstant: 80).isActive = true
        return button
    }()
    lazy var buttonToggleMic : UIButton = {
        let button = UIButton()
        button.setTitle("Toggle Mic", for: .normal)
        button.backgroundColor = .green
        button.isEnabled = true
        button.heightAnchor.constraint(equalToConstant: 80).isActive = true
        return button
    }()
    
    lazy var toggleCameraBtn : UIButton = {
        let button = UIButton()
        button.setTitle("Toggle Camera", for: .normal)
        button.backgroundColor = .blue
        button.isEnabled = true
        button.heightAnchor.constraint(equalToConstant: 80).isActive = true
        return button
    }()
    
    lazy var switchCameraBtn : UIButton = {
        let button = UIButton()
        button.setTitle("Switch Camera", for: .normal)
        button.backgroundColor = .magenta
        button.isEnabled = true
        button.heightAnchor.constraint(equalToConstant: 80).isActive = true
        return button
    }()
    
    lazy var mirrorBtn : UIButton = {
        let button = UIButton()
        button.setTitle("Mirror camera", for: .normal)
        button.backgroundColor = .cyan
        button.isEnabled = true
        button.heightAnchor.constraint(equalToConstant: 80).isActive = true
        return button
    }()
    
    lazy var speakerBtn : UIButton = {
        let button = UIButton()
        button.setTitle("Speaker", for: .normal)
        button.backgroundColor = .yellow
        button.isEnabled = true
        button.heightAnchor.constraint(equalToConstant: 80).isActive = true
        return button
    }()
    
    lazy var room: Room = {
        return Room.Builder(deploy: "deploy", key: "key", roomId: "1")
            .setRoomDelegate(delegate: self)
            .setMetadata(json: JSON(["name": "TINTIN"]))
            .setPeerId(id: "IOS")
            .build()
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
//        AVAudioSession
        let stackView = UIStackView.init()
        let viewsStackHolder = UIStackView()
        viewsStackHolder.axis = .vertical
        stackView.axis = .vertical
        viewsStackHolder.addArrangedSubview(localView)
        viewsStackHolder.addArrangedSubview(remoteView)
//        stackView.addArrangedSubview(localView)
//        stackView.addArrangedSubview(remoteView)
        viewsStackHolder.distribution = .fillEqually
        stackView.addArrangedSubview(viewsStackHolder)
        stackView.addArrangedSubview(button)
        stackView.addArrangedSubview(buttonToggleMic)
        stackView.addArrangedSubview(toggleCameraBtn)
        stackView.addArrangedSubview(mirrorBtn)
        stackView.addArrangedSubview(switchCameraBtn)
        stackView.addArrangedSubview(speakerBtn)
        view.addSubview(stackView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        stackView.distribution = .fill
        
        button.addTarget(self, action: #selector(startLocalStream), for: .touchUpInside)
        buttonToggleMic.addTarget(self, action: #selector(toggleMic), for: .touchUpInside)
        toggleCameraBtn.addTarget(self, action: #selector(toggleCamera), for: .touchUpInside)
        mirrorBtn.addTarget(self, action: #selector(mirrorCamera), for: .touchUpInside)
        switchCameraBtn.addTarget(self, action: #selector(switchCamera), for: .touchUpInside)
        speakerBtn.addTarget(self, action: #selector(toggleSpeaker), for: .touchUpInside)
//        Room.Builder.init()
    }

    @objc func toggleSpeaker(){
        speakerOn = !speakerOn
        room.setSpeaker(enabled: speakerOn)
    }
    
    @objc func startLocalStream(){
//        room.startVideoCapture(renderer: localView)
        room.connect(onSuccess: {
            clients in
//            HANDLE SUCCESSFULL CONNECTION
        }, onError: {
            print("ERROR")
        })
    }
    
    @objc func switchCamera(){
        room.cameraPosistion.toggle()
    }
    
    @objc func toggleMic(){
        room.isMuted = !room.isMuted
    }
    
    @objc func toggleCamera(){
        room.isHidden = !room.isHidden
    }
    
    @objc func mirrorCamera(){
        localView.mirrored = !localView.mirrored
//        room.cameraPosistion.toggle()
    }
    
    func roomEvent(localPeerId: String, onLocalStream localStream: QMediaStream) {
        
        localView.track = localStream.videoTracks[0]
    }
    
    func roomEvent(client: Client, onStreamAdded remoteStream: QMediaStream) {
        remoteView.track = remoteStream.videoTracks[0]
    }
    
    func roomEvent(onStreamRemoved remotePeerId: String) {
        
    }
    
    func roomEvent(onClientRemoved remotePeerId: String) {
        
    }
    
    func roomEvent(onStreamDenied error: Error) {
        
    }
    
    func onConnectionEstablished() {
        
    }
}

