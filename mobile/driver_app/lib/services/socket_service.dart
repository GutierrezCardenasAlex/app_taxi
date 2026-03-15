import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';

class SocketService {
  WebSocketChannel connectDriverFeed({String? driverId, String? tripId}) {
    final wsBase = AppConfig.apiBaseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://')
        .replaceFirst(':3000', ':3005');
    final query = <String, String>{};
    if (driverId != null && driverId.isNotEmpty) query['driverId'] = driverId;
    if (tripId != null && tripId.isNotEmpty) query['tripId'] = tripId;
    final uri = Uri.parse('$wsBase/ws/locations').replace(queryParameters: query.isEmpty ? null : query);
    return WebSocketChannel.connect(uri);
  }
}
