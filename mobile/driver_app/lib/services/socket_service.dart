import 'package:web_socket_channel/web_socket_channel.dart';

class SocketService {
  WebSocketChannel connectDispatch() {
    return WebSocketChannel.connect(Uri.parse('ws://localhost:3005/ws/locations'));
  }
}

