// ignore_for_file: avoid_print

import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketClient {
  IO.Socket? socket;
  static SocketClient? _instance;

  SocketClient._internal() {
    socket = IO.io(
      "http://10.185.91.196:3000", 
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      },
    );

    socket!.connect();

    socket!.onConnect((_) {
      print("SOCKET CONNECTED");
    });

    socket!.onDisconnect((_) {
      print("SOCKET DISCONNECTED");
    });

    socket!.onConnectError((err) {
      print("CONNECT ERROR: $err");
    });

    socket!.onError((err) {
      print("sSOCKET ERROR: $err");
    });
  }

  static SocketClient get instance {
    _instance ??= SocketClient._internal();
    return _instance!;
  }
}
