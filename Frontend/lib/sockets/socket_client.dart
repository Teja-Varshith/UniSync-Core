// ignore_for_file: avoid_print

import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:UniSync/constants/constant.dart';

class SocketClient {
  IO.Socket? socket;
  static SocketClient? _instance;

  SocketClient._internal() {
    socket = IO.io(
      BACKEND_ORIGIN,
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'reconnection': true,
        'reconnectionAttempts': 5,
        'reconnectionDelay': 1500,
      },
    );

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
