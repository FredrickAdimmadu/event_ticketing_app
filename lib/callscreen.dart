import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:event/signallingservice.dart';


class CallScreen extends StatefulWidget {
  final String callerId, calleeId;
  final dynamic offer;
  final bool isAudioOnly;

  const CallScreen({
    Key? key, // Add the correct type here
    this.offer,
    required this.callerId,
    required this.calleeId,
    this.isAudioOnly = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final _localRTCVideoRenderer = RTCVideoRenderer();
  final _remoteRTCVideoRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  RTCPeerConnection? _rtcPeerConnection;
  bool isAudioOn = true, isVideoOn = true, isFrontCameraSelected = true;
  bool isLocalVideoExpanded = false;
  SignallingService signallingService = SignallingService();

  @override
  void initState() {
    _localRTCVideoRenderer.initialize();
    _remoteRTCVideoRenderer.initialize();
    _setupPeerConnection();
    signallingService.init(selfCallerID: widget.callerId);
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  _setupPeerConnection() async {
    _rtcPeerConnection = await createPeerConnection({
      'iceServers': [
        {
          'urls': [
            'stun:stun1.l.google.com:19302',
            'stun:stun2.l.google.com:19302'
          ]
        }
      ]
    });

    _rtcPeerConnection!.onTrack = (event) {
      _remoteRTCVideoRenderer.srcObject = event.streams[0];
      setState(() {});
    };

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': isAudioOn,
      'video': widget.isAudioOnly ? false : {
        'facingMode': isFrontCameraSelected ? 'user' : 'environment'
      },
    });

    _localStream!.getTracks().forEach((track) {
      _rtcPeerConnection!.addTrack(track, _localStream!);
    });

    _localRTCVideoRenderer.srcObject = _localStream;
    setState(() {});

    if (widget.offer != null) {
      // Handle incoming offer and send answer
      await _rtcPeerConnection!.setRemoteDescription(
        RTCSessionDescription(widget.offer["sdp"], widget.offer["type"]),
      );

      RTCSessionDescription answer = await _rtcPeerConnection!.createAnswer();
      await _rtcPeerConnection!.setLocalDescription(answer);

      signallingService.sendSignallingData({
        "event": "answerCall",
        "callerId": widget.callerId,
        "sdpAnswer": answer.sdp,
        "type": answer.type,
      });
    } else {
      // Make outgoing call and handle answer
      _rtcPeerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        signallingService.sendSignallingData({
          "event": "IceCandidate",
          "calleeId": widget.calleeId,
          "iceCandidate": {
            "id": candidate.sdpMid,
            "label": candidate.sdpMLineIndex,
            "candidate": candidate.candidate
          }
        });
      };

      RTCSessionDescription offer = await _rtcPeerConnection!.createOffer();
      await _rtcPeerConnection!.setLocalDescription(offer);

      signallingService.sendSignallingData({
        "event": "makeCall",
        "calleeId": widget.calleeId,
        "sdpOffer": offer.sdp,
        "type": offer.type,
      });
    }
  }

  _leaveCall() {
    _rtcPeerConnection?.close();
    Navigator.pop(context);
  }

  _toggleMic() {
    isAudioOn = !isAudioOn;
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = isAudioOn;
    });
    setState(() {});
  }

  _toggleCamera() {
    isVideoOn = !isVideoOn;
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = isVideoOn;
    });
    setState(() {});
  }

  _switchCamera() {
    isFrontCameraSelected = !isFrontCameraSelected;
    _localStream?.getVideoTracks().forEach((track) {
      track.switchCamera();
    });
    setState(() {});
  }

  _toggleLocalVideoSize() {
    setState(() {
      isLocalVideoExpanded = !isLocalVideoExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          title: const Text("Call Screen"),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    RTCVideoView(
                      _remoteRTCVideoRenderer,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                    if (!widget.isAudioOnly)
                      Positioned(
                        right: isLocalVideoExpanded ? 0 : 20,
                        bottom: isLocalVideoExpanded ? 0 : 20,
                        top: isLocalVideoExpanded ? 0 : null,
                        left: isLocalVideoExpanded ? 0 : null,
                        child: GestureDetector(
                          onTap: _toggleLocalVideoSize,
                          child: SizedBox(
                            height: isLocalVideoExpanded ? double.infinity : 150,
                            width: isLocalVideoExpanded ? double.infinity : 120,
                            child: RTCVideoView(
                              _localRTCVideoRenderer,
                              mirror: isFrontCameraSelected,
                              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                            ),
                          ),
                        ),
                      )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: Icon(isAudioOn ? Icons.mic : Icons.mic_off),
                      onPressed: _toggleMic,
                    ),
                    IconButton(
                      icon: const Icon(Icons.call_end),
                      iconSize: 30,
                      onPressed: _leaveCall,
                    ),
                    if (!widget.isAudioOnly) ...[
                      IconButton(
                        icon: const Icon(Icons.cameraswitch),
                        onPressed: _switchCamera,
                      ),
                      IconButton(
                        icon: Icon(isVideoOn ? Icons.videocam : Icons.videocam_off),
                        onPressed: _toggleCamera,
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _localRTCVideoRenderer.dispose();
    _remoteRTCVideoRenderer.dispose();
    _localStream?.dispose();
    _rtcPeerConnection?.dispose();
    super.dispose();
  }
}
