
# QCall Swift 📱
Swift library for video calls using Qüilo S.A servers. 

__Install QCall IOS__

With __cocoapods__  **(IOS >= 10)**  <img src="https://cocoapods.org/favicons/favicon.ico" width="30"/>
First add vivequilo specs source at top of your podfile

```ruby
source 'https://github.com/vivequilo/q-specs'
```
then in terminal run
```
pod repo add QCall https://github.com/vivequilo/q-specs
```

Last add the pod the pod to your target application in your podfile
```ruby
target '#TAGET_HERE' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  pod 'QCall'
end
```
> **Important!**  You must set bitcode enabled false in build setting for both pod and target using it.


## Example building a room
```swift
    lazy var room: Room = {
        return Room.Builder(deploy: "deploy", key: "key", roomId: "1")
            .setRoomDelegate(delegate: self)
            .setMetadata(json: JSON(["name": "TINTIN"]))
            .setPeerId(id: "IOS")
            .build()
    }()
```
## Example handle local stream event
```swift
	Class ControllerExample: UIViewController, RoomDelegate {
		lazy var localView: QVideoRenderer = {
        	return QVideoRenderer()
    	}()
    	// Add the view
		//All of the delegate functions ...
	    func roomEvent(localPeerId: String, onLocalStream localStream: QMediaStream) {    
	        localView.track = localStream.videoTracks[0]
	    }
	}
```
## Required permissions
Required permissions in Inf.plist
	- Privacy - Camera Usage Description
	- Privacy - Microphone Usage Description

> **Tip:**  You should always use room.close() when finishing the call.

##  QVideoRenderer

### Functions 👾
Name | Parameters | Description
--- | --- | ---
removeCurrentTrack |  | Removes the current track from the Video renderer

**Properties** 📦
Name | Type | Description
--- | --- | ---
renderView | `RTCEAGLVideoView?` | Raw renderer without wrapper View
track | `QVideoTrack?` | Getter of the current video track in the renderer. Setter sets the current track and plays it
mirrored | `Bool` | Value if the view is mirrored or not usefull for front view.

## Client Class
**Properties** 📦
Name | Type | Description
--- | --- | ---
id | `String` | String value for the peer id.
metadata | `JSON` | Metadata for the Client class.
call | `MediaConnection?` | Media connection instance of the caller.
conn | `DataConnection?` | Data connection instance of the caller.
stream | `QMediaStream?` | Stream of the caller


## Room Class
> **Tip:**  If you want to reduce the quality go check the QVideoResolutionConstraint.
> To set it you must use the functions **setIdealVideoResolution, setMaxFrameRate...** in the builder.

**Properties** 📦
Name | Type | Description
--- | --- | ---
delegate | `RoomDelegate?` | Room events delegate watches over the events of the room
localClient | `Client` | Local client.
id | `String` | Room id value.
peerId | `String` | Peer id value setted in the builder
metadata | `JSON` | Metadata of the caller.
cameraPosistion | `CameraPosition` | Camera Position of the call. You can changle it by hand or use the mutating function .toggle() .
isMuted | `Boolean` | Value if the muted is muted or not. To mute it you can set value in here.
isHidden | `Boolean` | Value if the current video track is hidden or not. To change it you can set value in here.
localStream | `QMediaStream?` | Getter of the current media stream.
clients | `[Clients]` | Clients in the call array


**Functions** 👾
Name | Parameters | Description | Returns
--- | --- | --- | ---
setSpeaker | `enabled: Bool` | Sets if the speaker mode is enabled or not. | Void
toggleCamera |  | Wrapper function that toggles the camera in the call. | Void
connect | `onSuccess: (([Client]) -> Void)?, onError: (() -> Void)?`| Connects the user to the room. | Void
close |  | Closes the room and the connections gracefully. | Void
setIsMute | `isMuted: Bool` | Sets if the call is muted if you preferer to use the function instead of setter of isMuted. | Void
setIsHidden | `isHidden: Bool` | Sets if the video of the call is hidden if you preferer to use the function instead of setter of isHidden. | Void
startVideoCapture |  | Starts the capture. | Void
startVideoCapture | `renderer: QVideoRenderer` | Starts the capture and sets the current video track on the renderer. | Void


### Builder 🛠
Data class to build a Room Class instance.

**Constructor** 🔨
Name | Type | Description
--- | --- | ---
roomId | `String` | The room id.
deploy | `String` | The deploy parameter where to build the room.
key | `String`| The api key provided by Qüilo S.A to connect the server.

**Functions** 👾
Name | Parameters | Description | Returns
--- | --- | ---
setPeerId | `id: String` | Sets the peerId to the room. | Builder
setRoomDelegate | `delegate: RoomDelegate?` | Sets the room Delegate. | Builder
setMetadata | `meta: JSON` | Sets the metadata to the room. | Builder
setVideoResolutionConstraints | `constraints: QVideoResolutionConstraint` | Sets the video resolution constraints. | Builder
setMaxVideoResolution | `width: Int, height: Int` | Sets the max video resolution. | Builder
setMinVideoResolution | `width: Int, height: Int` | Sets the min video resolution. | Builder
setIdealVideoResolution | `width: Int, height: Int` | Sets the ideal video resolution. | Builder
setMaxFrameRate | `rate: Int` | Sets the max frame rate to the room. | Builder
setIdealFrameRate | `rate: Int` | Sets the ideal frame rate to the room. | Builder
setMinFrameRate | `rate: Int` | Sets the min frame rate to the room. | Builder
setDataDelegate | `delegate: DataConnectionDelegate?` | Sets the data channel delegate. | Builder
build | | Returns the Room instance | Room


## Delegates 🔬

### RoomDelegate 

Delegate for room events.

**Functions** 👾
Name | Parameters | Description | Returns
--- | --- | --- | ---
roomEvent | `localPeerId : String, onLocalStream localStream: QMediaStream` | Callback when the local stream is set. | Void
roomEvent | `client : Client, onStreamAdded remoteStream: QMediaStream` | Callback when a remote stream is added to the room. | Void
roomEvent | `onStreamRemoved remotePeerId : String` | Callback when a remote stream is removed to the room. | Void
roomEvent | `onClientRemoved remotePeerId: String` | Callback when a remote client is removed to the room. | Void
roomEvent | `onStreamDenied error: Error` | Callback when a stream is denied. | Void
onConnectionEstablished | | Callback when the local client connects to the server (Not the call itself necessarily). | Void

### DataConnectionDelegate
Delegate for data channel.
**Functions** 👾
Name | Parameters | Description | Returns
--- | --- | --- | ---
onDataConnectionOpen | | Data channel with a remote peer openned. | Void
onDataConnectionClosed | | Data connection closed. | Void
message | `onMessageFailed error : String`| Callback when there was an error parsing data. | Void
message | `onDataJson json : JSON`| Callback when datachannel received a JSON object. | Void
message | `onDataString message : String`| Callback when string message received on data channel. | Void



