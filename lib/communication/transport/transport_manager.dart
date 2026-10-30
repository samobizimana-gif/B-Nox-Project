import '../../core/account_manager.dart';
import 'webrtc_transport.dart';

class TransportManager {
  TransportManager._();
  static WebRtcTransport? _instance;

  static void init(Account account) {
    _instance = WebRtcTransport(localBnoxId: account.bnoxId);
  }

  static WebRtcTransport? get transport => _instance;
}