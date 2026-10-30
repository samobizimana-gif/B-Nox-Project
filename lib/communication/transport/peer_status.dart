enum PeerConnectionState {
  disconnected,
  connecting,
  connected,
  failed,
}

class PeerStatus {
  final String bnoxId;
  final PeerConnectionState state;

  PeerStatus({required this.bnoxId, required this.state});

  bool get isOnline => state == PeerConnectionState.connected;
}