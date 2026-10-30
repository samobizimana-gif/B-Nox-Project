import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../core/message.dart';
import 'peer_status.dart';

class WebRtcTransport {
  final String localBnoxId;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  final _messageCtrl = StreamController<Message>.broadcast();
  final _statusCtrl = StreamController<PeerStatus>.broadcast();

  final Map<String, RTCPeerConnection> _connections = {};
  final Map<String, RTCDataChannel> _channels = {};

  WebRtcTransport({required this.localBnoxId});

  Stream<Message> get messages => _messageCtrl.stream;
  Stream<PeerStatus> get peerStatus => _statusCtrl.stream;

  Future<void> connect(String peerBnoxId) async {
    if (_connections.containsKey(peerBnoxId)) return;

    _statusCtrl.add(PeerStatus(bnoxId: peerBnoxId, state: PeerConnectionState.connecting));

    try {
      final config = {'iceServers': [{'urls': 'stun:stun.l.google.com:19302'}]};
      final pc = await createPeerConnection(config);
      _connections[peerBnoxId] = pc;

      final channel = await pc.createDataChannel('bnox', RTCDataChannelInit()..ordered = true);
      _channels[peerBnoxId] = channel;

      channel.onMessage = (msg) {
        final message = Message.fromJson(jsonDecode(msg.text));
        _messageCtrl.add(message);
      };

      channel.onDataChannelState = (state) {
        if (state == RTCDataChannelState.RTCDataChannelOpen) {
          _statusCtrl.add(PeerStatus(bnoxId: peerBnoxId, state: PeerConnectionState.connected));
        }
      };

      pc.onIceCandidate = (candidate) {
        if (candidate.candidate != null) {
          _db.child('signaling/$localBnoxId/$peerBnoxId/candidates').push().set({
            'from': localBnoxId,
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          });
        }
      };

      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);

      await _db.child('signaling/$localBnoxId/$peerBnoxId/offer').set({
        'from': localBnoxId,
        'sdp': offer.sdp,
        'type': offer.type,
      });

      _listenForAnswer(peerBnoxId, pc);
      _listenForCandidates(peerBnoxId, pc);
    } catch (e) {
      _statusCtrl.add(PeerStatus(bnoxId: peerBnoxId, state: PeerConnectionState.failed));
    }
  }

  void _listenForAnswer(String peerBnoxId, RTCPeerConnection pc) {
    _db.child('signaling/$localBnoxId/$peerBnoxId/answer').onValue.listen((event) async {
      final data = event.snapshot.value;
      if (data == null) return;
      final map = Map<String, dynamic>.from(data as Map);
      await pc.setRemoteDescription(RTCSessionDescription(map['sdp'], map['type']));
      await _db.child('signaling/$localBnoxId/$peerBnoxId/answer').remove();
    });
  }

  void _listenForCandidates(String peerBnoxId, RTCPeerConnection pc) {
    _db.child('signaling/$localBnoxId/$peerBnoxId/candidates').onChildAdded.listen((event) async {
      final data = event.snapshot.value;
      if (data == null) return;
      final map = Map<String, dynamic>.from(data as Map);
      await pc.addCandidate(RTCIceCandidate(map['candidate'], map['sdpMid'], map['sdpMLineIndex']));
    });
  }

  Future<void> send(Message message) async {
    final channel = _channels[message.to];
    if (channel == null || channel.state != RTCDataChannelState.RTCDataChannelOpen) {
      throw Exception('Pas de connexion avec ${message.to}');
    }
    channel.send(RTCDataChannelMessage(jsonEncode(message.toJson())));
  }

  Future<void> disconnect(String peerBnoxId) async {
    await _channels[peerBnoxId]?.close();
    await _connections[peerBnoxId]?.close();
    _channels.remove(peerBnoxId);
    _connections.remove(peerBnoxId);
  }

  Future<void> dispose() async {
    for (var id in _connections.keys.toList()) {
      await disconnect(id);
    }
    await _messageCtrl.close();
    await _statusCtrl.close();
  }
}