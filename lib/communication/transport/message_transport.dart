import '../core/message.dart';
import 'peer_status.dart';

abstract class MessageTransport {
  Stream<Message> get messages;
  Stream<PeerStatus> get peerStatus;
  Future<void> connect(String peerBnoxId);
  Future<void> send(Message message);
  Future<void> disconnect(String peerBnoxId);
  Future<void> dispose();
}