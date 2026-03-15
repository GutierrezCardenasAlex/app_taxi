import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';

class SocketService {
  WebSocketChannel connectLocations({String? tripId, String? driverId}) {
    final wsBase = AppConfig.apiBaseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://')
        .replaceFirst(':3000', ':3005');
    final query = <String, String>{};
    if (tripId != null && tripId.isNotEmpty) query['tripId'] = tripId;
    if (driverId != null && driverId.isNotEmpty) query['driverId'] = driverId;
    final uri = Uri.parse('$wsBase/ws/locations').replace(queryParameters: query.isEmpty ? null : query);
    return WebSocketChannel.connect(uri);
  }
}
